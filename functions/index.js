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

    // 🔄 주문 상태 업데이트 (pending → confirmed)
    await updateOrderStatusToConfirmed(orderId, paymentKey);

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
 * 🔄 주문 상태를 'pending'에서 'confirmed'로 업데이트
 *
 * 결제 승인 성공 후 주문 상태를 업데이트합니다.
 * 트랜잭션을 사용하여 원자성을 보장합니다.
 *
 * @param {string} orderId - 주문 ID
 * @param {string} paymentKey - 결제 키
 */
async function updateOrderStatusToConfirmed(orderId, paymentKey) {
  try {
    functions.logger.info("📦 주문 상태 업데이트 시작", {
      orderId,
      paymentKey,
    });

    await admin.firestore().runTransaction(async (transaction) => {
      // 1️⃣ 주문 문서 조회
      const orderRef = admin.firestore().collection("orders").doc(orderId);
      const orderDoc = await transaction.get(orderRef);

      if (!orderDoc.exists) {
        throw new Error(`주문을 찾을 수 없습니다: ${orderId}`);
      }

      const orderData = orderDoc.data();
      const currentStatus = orderData.status;

      // 2️⃣ 현재 상태 확인
      if (currentStatus !== "pending") {
        functions.logger.warn("주문 상태가 pending이 아닙니다", {
          orderId,
          currentStatus,
        });

        // pending이 아닌 경우 이미 처리되었을 수 있으므로 에러를 던지지 않음
        return;
      }

      // 3️⃣ 주문 상태 업데이트
      transaction.update(orderRef, {
        status: "confirmed",
        paymentInfo: {
          paymentKey: paymentKey,
          confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      functions.logger.info("✅ 주문 상태 업데이트 완료", {
        orderId,
        oldStatus: currentStatus,
        newStatus: "confirmed",
      });
    });
  } catch (error) {
    // 주문 상태 업데이트 실패는 결제 성공에 영향을 주지 않음
    functions.logger.error("⚠️ 주문 상태 업데이트 실패 (결제는 성공)", {
      orderId,
      error: error.message,
    });

    // 오류 로그만 남기고 예외를 던지지 않음
    // 결제는 이미 성공했으므로 사용자에게는 성공으로 처리
  }
}

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
        "필수 파라미터 누락: paymentKey, cancelReason",
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

    // 🔍 1단계: 관련 주문 조회 (환불 전 주문 정보 확인)
    let orderId = null;
    let originalTotalAmount = null;

    const ordersSnapshot = await admin.firestore()
        .collection("orders")
        .where("paymentInfo.paymentKey", "==", paymentKey)
        .limit(1)
        .get();

    if (!ordersSnapshot.empty) {
      const orderDoc = ordersSnapshot.docs[0];
      const orderData = orderDoc.data();
      orderId = orderData.orderId;
      originalTotalAmount = orderData.totalAmount;

      functions.logger.info("관련 주문 찾음", {
        orderId,
        originalTotalAmount,
        paymentKey,
      });
    }

    // 💳 2단계: 토스페이먼츠 환불 API 호출
    const response = await axios.post(
        `https://api.tosspayments.com/v1/payments/${paymentKey}/cancel`,
        refundData,
        {headers},
    );

    // 환불 성공 - 데이터베이스에 저장
    const refundResult = response.data;

    // 🔄 3단계: 전액 환불 여부 판단
    const isFullRefund = !cancelAmount || cancelAmount === originalTotalAmount;

    // 📦 4단계: Firestore 트랜잭션으로 모든 업데이트 수행
    await admin.firestore().runTransaction(async (transaction) => {
      // 환불 내역을 별도 컬렉션에 저장
      const refundRecord = {
        paymentKey,
        orderId: orderId || null,
        userId: context.auth.uid,
        cancelReason,
        cancelAmount: cancelAmount ||
          refundResult.totalAmount || originalTotalAmount,
        refundReceiveAccount: refundReceiveAccount || null,
        idempotencyKey: idempotencyKey || null,
        refundResult,
        isFullRefund,
        refundedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "COMPLETED",
      };

      const refundDocRef = admin.firestore()
          .collection("refunds")
          .doc(`${paymentKey}_${Date.now()}`);

      transaction.set(refundDocRef, refundRecord);

      // 원본 결제 정보 업데이트
      const paymentDocRef = admin.firestore()
          .collection("payments")
          .doc(paymentKey);

      transaction.update(paymentDocRef, {
        status: refundResult.status, // CANCELED 또는 PARTIAL_CANCELED
        refunds: admin.firestore.FieldValue.arrayUnion(refundRecord),
        lastRefundedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 🎯 5단계: 주문 상태 업데이트 (전액 환불인 경우)
      if (orderId && isFullRefund) {
        const orderDocRef = admin.firestore()
            .collection("orders")
            .doc(orderId);

        // 주문 문서 존재 확인
        const orderDoc = await transaction.get(orderDocRef);
        if (orderDoc.exists) {
          const currentOrderData = orderDoc.data();

          functions.logger.info("전액 환불 - 주문 상태 업데이트", {
            orderId,
            currentStatus: currentOrderData.status,
            newStatus: "cancelled",
            refundAmount: cancelAmount || originalTotalAmount,
          });

          transaction.update(orderDocRef, {
            status: "cancelled",
            cancelReason: `전액 환불: ${cancelReason}`,
            canceledAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          functions.logger.warn("주문 문서를 찾을 수 없음", {orderId, paymentKey});
        }
      } else if (orderId && !isFullRefund) {
        // 부분 환불인 경우 환불 기록만 추가 (주문 상태는 유지)
        const orderDocRef = admin.firestore()
            .collection("orders")
            .doc(orderId);

        const orderDoc = await transaction.get(orderDocRef);
        if (orderDoc.exists) {
          functions.logger.info("부분 환불 - 환불 기록 추가", {
            orderId,
            refundAmount: cancelAmount,
            remainingAmount: (originalTotalAmount || 0) - (cancelAmount || 0),
          });

          transaction.update(orderDocRef, {
            refundHistory: admin.firestore.FieldValue.arrayUnion({
              refundAmount: cancelAmount,
              refundReason: cancelReason,
              refundedAt: admin.firestore.FieldValue.serverTimestamp(),
              refundResult: refundResult.status,
            }),
            lastRefundedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      functions.logger.info("모든 데이터베이스 업데이트 완료", {
        paymentKey,
        orderId,
        isFullRefund,
        refundAmount: cancelAmount || "전액",
      });
    });

    functions.logger.info("환불 처리 성공", {
      paymentKey,
      orderId,
      cancelAmount: cancelAmount || "전액",
      newStatus: refundResult.status,
      userId: context.auth.uid,
      isFullRefund,
    });

    return {
      success: true,
      refund: refundResult,
      orderId: orderId,
      isFullRefund: isFullRefund,
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

/**
 * 🗑️ 결제 실패 시 대기 중인 주문 삭제 Cloud Function
 *
 * 결제 실패 시 pending 상태의 주문을 삭제하고 재고를 복구합니다.
 * 클라이언트 측 실패뿐만 아니라 웹훅을 통한 실패도 처리할 수 있습니다.
 */
exports.deletePendingOrderOnPaymentFailure = functions.https.onCall(
    async (data, context) => {
      // 사용자 인증 확인
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "사용자 인증이 필요합니다.",
        );
      }

      const {orderId, reason} = data;

      // 필수 파라미터 검증
      if (!orderId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "orderId가 필요합니다.",
        );
      }

      try {
        functions.logger.info("🗑️ 결제 실패로 인한 주문 삭제 시작", {
          orderId,
          reason: reason || "결제 실패",
          userId: context.auth.uid,
        });

        // 트랜잭션으로 원자적 처리
        const result = await admin.firestore().runTransaction(
            async (transaction) => {
              // 1️⃣ 주문 조회 및 상태 확인
              const orderRef = admin.firestore()
                  .collection("orders").doc(orderId);
              const orderDoc = await transaction.get(orderRef);

              if (!orderDoc.exists) {
                functions.logger.warn("삭제할 주문을 찾을 수 없음", {orderId});
                return {
                  success: false,
                  message: "주문을 찾을 수 없습니다.",
                  orderId,
                };
              }

              const orderData = orderDoc.data();
              const orderStatus = orderData.status;
              const orderUserId = orderData.userId;

              // 주문 소유자 확인
              if (orderUserId !== context.auth.uid) {
                throw new functions.https.HttpsError(
                    "permission-denied",
                    "주문에 대한 권한이 없습니다.",
                );
              }

              // pending 상태가 아닌 경우 삭제하지 않음
              if (orderStatus !== "pending") {
                functions.logger.warn("pending 상태가 아닌 주문은 삭제하지 않음", {
                  orderId,
                  currentStatus: orderStatus,
                });
                return {
                  success: false,
                  message: `pending 상태가 아닌 주문은 삭제할 수 없습니다. ` +
                    `현재 상태: ${orderStatus}`,
                  orderId,
                  currentStatus: orderStatus,
                };
              }

              // 결제 정보 확인 (이미 결제가 완료된 경우 삭제 방지)
              const paymentInfo = orderData.paymentInfo;
              if (paymentInfo && paymentInfo.status === "DONE") {
                functions.logger.warn("이미 결제가 완료된 주문은 삭제하지 않음", {
                  orderId,
                  paymentStatus: paymentInfo.status,
                });
                return {
                  success: false,
                  message: "이미 결제가 완료된 주문은 삭제할 수 없습니다.",
                  orderId,
                };
              }

              functions.logger.info("✅ 삭제 가능한 pending 주문 확인", {orderId});

              // 2️⃣ 주문 상품 조회 및 재고 복구
              const orderedProductsSnapshot = await admin.firestore()
                  .collection("orders")
                  .doc(orderId)
                  .collection("ordered_products")
                  .get();

              functions.logger.info("📦 복구할 주문 상품 수", {
                orderId,
                productCount: orderedProductsSnapshot.docs.length,
              });

              const stockRestorations = [];

              for (const doc of orderedProductsSnapshot.docs) {
                const orderedProduct = doc.data();
                const productId = orderedProduct.productId;
                const quantity = orderedProduct.quantity;
                const productName = orderedProduct.productName;

                // 상품 재고 복구
                const productRef = admin.firestore()
                    .collection("products").doc(productId);
                const productDoc = await transaction.get(productRef);

                if (productDoc.exists) {
                  const productData = productDoc.data();
                  const currentStock = productData.stock || 0;
                  const restoredStock = currentStock + quantity;

                  transaction.update(productRef, {
                    stock: restoredStock,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                  });

                  stockRestorations.push({
                    productId,
                    productName,
                    quantity,
                    stockBefore: currentStock,
                    stockAfter: restoredStock,
                  });

                  functions.logger.info("📈 재고 복구", {
                    productId,
                    productName,
                    quantity,
                    stockBefore: currentStock,
                    stockAfter: restoredStock,
                  });
                } else {
                  functions.logger.warn("상품을 찾을 수 없어 재고 복구 불가", {
                    productId,
                    productName,
                  });
                }

                // 3️⃣ 주문 상품 서브컬렉션 문서 삭제
                transaction.delete(doc.ref);
              }

              // 4️⃣ 사용자 문서에서 주문 ID 제거
              const userRef = admin.firestore()
                  .collection("users").doc(context.auth.uid);
              const userDoc = await transaction.get(userRef);

              if (userDoc.exists) {
                transaction.update(userRef, {
                  orderIds: admin.firestore.FieldValue.arrayRemove(orderId),
                  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                functions.logger.info("👤 사용자 문서에서 주문 ID 제거", {
                  userId: context.auth.uid,
                  orderId,
                });
              }

              // 5️⃣ 주문 삭제 로그 기록 (삭제 전)
              const deletionLogRef = admin.firestore()
                  .collection("order_deletion_logs").doc();
              transaction.set(deletionLogRef, {
                orderId,
                userId: context.auth.uid,
                reason: reason || "결제 실패",
                originalOrderData: orderData,
                stockRestorations,
                deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                deletedBy: "payment_failure_function",
              });

              // 6️⃣ 주문 문서 삭제
              transaction.delete(orderRef);

              functions.logger.info("🗑️ 주문 문서 삭제 완료", {orderId});

              return {
                success: true,
                message: "주문이 성공적으로 삭제되었습니다.",
                orderId,
                stockRestorations,
                deletedProductCount: orderedProductsSnapshot.docs.length,
              };
            });

        functions.logger.info("✅ 결제 실패 주문 삭제 완료", {
          orderId,
          result,
          userId: context.auth.uid,
        });

        return result;
      } catch (error) {
        functions.logger.error("❌ 결제 실패 주문 삭제 실패", {
          orderId,
          error: error.message,
          userId: context.auth.uid,
        });

        // 이미 HttpsError인 경우 그대로 throw
        if (error instanceof functions.https.HttpsError) {
          throw error;
        }

        throw new functions.https.HttpsError(
            "internal",
            `주문 삭제 중 오류가 발생했습니다: ${error.message}`,
        );
      }
    });
