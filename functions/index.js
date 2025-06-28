/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

// Firebase Admin 초기화
admin.initializeApp();

/**
 * 🔒 토스페이먼츠 결제 승인 Cloud Function
 *
 * 보안: 시크릿 키는 Firebase Functions 환경 변수에서만 관리
 * 클라이언트에서는 절대 시크릿 키에 접근할 수 없음
 */
exports.confirmPayment = functions.https.onCall(async (data, context) => {
  // 사용자 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "사용자 인증이 필요합니다.",
    );
  }

  const {paymentKey, orderId, amount} = data;

  // 필수 파라미터 검증
  if (!paymentKey || !orderId || !amount) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "필수 파라미터가 누락되었습니다: paymentKey, orderId, amount",
    );
  }

  try {
    // 🔐 환경 변수에서 시크릿 키 가져오기 (서버에서만 접근 가능)
    const secretKey = functions.config().toss.secret_key;
    if (!secretKey) {
      throw new functions.https.HttpsError(
          "internal",
          "토스페이먼츠 시크릿 키가 설정되지 않았습니다.",
      );
    }

    // Basic 인증 헤더 생성 (시크릿 키 + ':' 를 base64 인코딩)
    const authHeader = "Basic " +
      Buffer.from(secretKey + ":").toString("base64");

    // 토스페이먼츠 결제 승인 API 호출
    const response = await axios.post(
        `https://api.tosspayments.com/v1/payments/confirm`,
        {
          paymentKey,
          orderId,
          amount,
        },
        {
          headers: {
            "Authorization": authHeader,
            "Content-Type": "application/json",
          },
        },
    );

    // 결제 승인 성공 - 데이터베이스에 저장
    const paymentData = response.data;
    await admin.firestore().collection("payments").doc(paymentKey).set({
      ...paymentData,
      userId: context.auth.uid,
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "CONFIRMED",
    });

    // 🛒 결제 승인 성공 후 장바구니에서 주문된 상품들 삭제
    await removeOrderedItemsFromCart(orderId, context.auth.uid);

    functions.logger.info("결제 승인 성공", {
      paymentKey,
      orderId,
      amount,
      userId: context.auth.uid,
    });

    return {
      success: true,
      payment: paymentData,
    };
  } catch (error) {
    functions.logger.error("결제 승인 실패", {
      paymentKey,
      orderId,
      amount,
      error: error.message,
      userId: context.auth.uid,
    });

    // 토스페이먼츠 API 에러 처리
    if (error.response && error.response.data) {
      throw new functions.https.HttpsError(
          "failed-precondition",
          `결제 승인 실패: ${error.response.data.message}`,
          error.response.data,
      );
    }

    throw new functions.https.HttpsError(
        "internal",
        "결제 승인 중 오류가 발생했습니다.",
    );
  }
});

/**
 * 🔔 토스페이먼츠 웹훅 처리 Cloud Function
 *
 * 결제 상태 변경 시 실시간 알림 처리
 */
exports.handlePaymentWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const webhookData = req.body;
    const {eventType, data: paymentData} = webhookData;

    functions.logger.info("웹훅 수신", {
      eventType,
      paymentKey: paymentData?.paymentKey,
    });

    // 결제 상태에 따른 처리
    switch (eventType) {
      case "PAYMENT_STATUS_CHANGED":
        await handlePaymentStatusChanged(paymentData);
        break;
      default:
        functions.logger.warn("처리되지 않은 웹훅 이벤트", {eventType});
    }

    res.status(200).send("OK");
  } catch (error) {
    functions.logger.error("웹훅 처리 실패", {error: error.message});
    res.status(500).send("Internal Server Error");
  }
});

/**
 * 결제 상태 변경 처리
 * @param {object} paymentData - 결제 데이터 객체
 */
async function handlePaymentStatusChanged(paymentData) {
  const {paymentKey, status} = paymentData;

  if (!paymentKey) {
    throw new Error("paymentKey가 없습니다.");
  }

  // Firestore에 결제 상태 업데이트
  await admin.firestore().collection("payments").doc(paymentKey).update({
    status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    webhookData: paymentData,
  });

  functions.logger.info("결제 상태 업데이트 완료", {paymentKey, status});
}

/**
 * 🛒 장바구니에서 주문된 상품들 삭제 처리
 *
 * 결제 성공 후 해당 주문의 상품들을 사용자 장바구니에서 소프트 삭제합니다.
 * 오류가 발생해도 결제는 이미 완료되었으므로 로그만 남기고 진행합니다.
 *
 * @param {string} orderId - 주문 ID
 * @param {string} userId - 사용자 ID
 */
async function removeOrderedItemsFromCart(orderId, userId) {
  try {
    functions.logger.info("🛒 장바구니에서 주문된 상품 삭제 시작", {
      orderId,
      userId,
    });

    // 1️⃣ 주문된 상품 목록 조회
    const orderedProductsSnapshot = await admin
        .firestore()
        .collection("orders")
        .doc(orderId)
        .collection("ordered_products")
        .get();

    if (orderedProductsSnapshot.empty) {
      functions.logger.warn("주문된 상품이 없습니다", {orderId});
      return;
    }

    // 2️⃣ 삭제할 cartItemId 목록 추출
    const cartItemIds = orderedProductsSnapshot.docs.map((doc) => {
      return doc.data().cartItemId;
    }).filter((id) => id); // cartItemId가 없는 경우 제외

    if (cartItemIds.length === 0) {
      functions.logger.warn("삭제할 cartItemId가 없습니다.", {orderId});
      return;
    }

    functions.logger.info("삭제할 장바구니 아이템 ID 목록", {
      orderId,
      cartItemIds,
    });

    // 3️⃣ 사용자 장바구니에서 해당 상품들을 소프트 삭제
    const cartItemsCollection = admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("cart");

    // 배치 업데이트를 위한 batch 생성
    const batch = admin.firestore().batch();

    // 각 cartItemId에 대해 직접 문서 참조를 만들어 업데이트
    cartItemIds.forEach((cartItemId) => {
      const cartItemRef = cartItemsCollection.doc(cartItemId);
      batch.update(cartItemRef, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        deletedReason: `주문 완료 (주문번호: ${orderId})`,
      });
    });

    // 4️⃣ 배치 업데이트 실행
    await batch.commit();
    functions.logger.info("✅ 장바구니에서 주문된 상품 삭제 완료", {
      orderId,
      userId,
      deletedItemsCount: cartItemIds.length,
    });
  } catch (error) {
    // 장바구니 삭제 실패는 결제 성공에 영향을 주지 않음
    functions.logger.error("⚠️ 장바구니 삭제 실패 (결제는 성공)", {
      orderId,
      userId,
      error: error.message,
    });

    // 오류 로그만 남기고 예외를 던지지 않음
    // 결제는 이미 성공했으므로 사용자에게는 성공으로 처리
  }
}

/**
 * 🔒 토스페이먼츠 환불 처리 Cloud Function
 *
 * 보안: 시크릿 키는 Firebase Functions 환경 변수에서만 관리
 * 전액 환불과 부분 환불 지원, 가상계좌 환불 시 계좌 정보 처리
 */
exports.refundPayment = functions.https.onCall(async (data, context) => {
  // 사용자 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "사용자 인증이 필요합니다.",
    );
  }

  const {
    paymentKey,
    cancelReason,
    cancelAmount, // 부분 환불 시 사용, 없으면 전액 환불
    refundReceiveAccount, // 가상계좌 환불 시 필수
    idempotencyKey, // 중복 환불 방지용 멱등키
  } = data;

  // 필수 파라미터 검증
  if (!paymentKey || !cancelReason) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "필수 파라미터가 누락되었습니다: paymentKey, cancelReason",
    );
  }

  try {
    // 🔐 환경 변수에서 시크릿 키 가져오기 (서버에서만 접근 가능)
    const secretKey = functions.config().toss.secret_key;
    if (!secretKey) {
      throw new functions.https.HttpsError(
          "internal",
          "토스페이먼츠 시크릿 키가 설정되지 않았습니다.",
      );
    }

    // Basic 인증 헤더 생성 (시크릿 키 + ':' 를 base64 인코딩)
    const authHeader = "Basic " +
      Buffer.from(secretKey + ":").toString("base64");

    // 환불 요청 데이터 구성
    const refundData = {
      cancelReason,
    };

    // 부분 환불인 경우 금액 추가
    if (cancelAmount) {
      refundData.cancelAmount = cancelAmount;
    }

    // 가상계좌 환불인 경우 계좌 정보 추가
    if (refundReceiveAccount) {
      refundData.refundReceiveAccount = refundReceiveAccount;
    }

    // 요청 헤더 구성
    const headers = {
      "Authorization": authHeader,
      "Content-Type": "application/json",
    };

    // 멱등키가 있는 경우 헤더에 추가 (중복 환불 방지)
    if (idempotencyKey) {
      headers["Idempotency-Key"] = idempotencyKey;
    }

    functions.logger.info("환불 요청 시작", {
      paymentKey,
      cancelReason,
      cancelAmount: cancelAmount || "전액 환불",
      userId: context.auth.uid,
      hasRefundAccount: !!refundReceiveAccount,
      idempotencyKey,
    });

    // 토스페이먼츠 환불 API 호출
    const response = await axios.post(
        `https://api.tosspayments.com/v1/payments/${paymentKey}/cancel`,
        refundData,
        {headers},
    );

    // 환불 성공 - 데이터베이스에 저장
    const refundResult = response.data;

    // 환불 내역을 별도 컬렉션에 저장
    const refundRecord = {
      paymentKey,
      userId: context.auth.uid,
      cancelReason,
      cancelAmount: cancelAmount || refundResult.totalAmount,
      refundReceiveAccount: refundReceiveAccount || null,
      idempotencyKey: idempotencyKey || null,
      refundResult,
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "COMPLETED",
    };

    await admin.firestore()
        .collection("refunds")
        .doc(`${paymentKey}_${Date.now()}`)
        .set(refundRecord);

    // 원본 결제 정보 업데이트
    await admin.firestore()
        .collection("payments")
        .doc(paymentKey)
        .update({
          status: refundResult.status, // CANCELED 또는 PARTIAL_CANCELED
          refunds: admin.firestore.FieldValue.arrayUnion(refundRecord),
          lastRefundedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    functions.logger.info("환불 처리 성공", {
      paymentKey,
      cancelAmount: cancelAmount || "전액",
      newStatus: refundResult.status,
      userId: context.auth.uid,
    });

    return {
      success: true,
      refund: refundResult,
      refundRecord,
    };
  } catch (error) {
    functions.logger.error("환불 처리 실패", {
      paymentKey,
      cancelReason,
      cancelAmount,
      error: error.message,
      userId: context.auth.uid,
    });

    // 토스페이먼츠 API 에러 처리
    if (error.response && error.response.data) {
      throw new functions.https.HttpsError(
          "failed-precondition",
          `환불 처리 실패: ${error.response.data.message}`,
          error.response.data,
      );
    }

    throw new functions.https.HttpsError(
        "internal",
        "환불 처리 중 오류가 발생했습니다.",
    );
  }
});

/**
 * 🔍 사용자 환불 내역 조회 Cloud Function
 */
exports.getUserRefunds = functions.https.onCall(async (data, context) => {
  // 사용자 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "사용자 인증이 필요합니다.",
    );
  }

  const {limit = 20, startAfter} = data;

  try {
    let query = admin.firestore()
        .collection("refunds")
        .where("userId", "==", context.auth.uid)
        .orderBy("refundedAt", "desc")
        .limit(limit);

    if (startAfter) {
      query = query.startAfter(startAfter);
    }

    const snapshot = await query.get();
    const refunds = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    functions.logger.info("환불 내역 조회", {
      userId: context.auth.uid,
      count: refunds.length,
    });

    return {
      success: true,
      refunds,
      hasMore: snapshot.docs.length === limit,
    };
  } catch (error) {
    functions.logger.error("환불 내역 조회 실패", {
      userId: context.auth.uid,
      error: error.message,
    });

    throw new functions.https.HttpsError(
        "internal",
        "환불 내역 조회 중 오류가 발생했습니다.",
    );
  }
});
