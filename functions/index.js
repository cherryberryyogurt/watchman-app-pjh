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
