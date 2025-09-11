import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Firebase Admin 초기화
admin.initializeApp();

// 관리자 권한 부여 함수
export const setAdminUser = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  // 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  // 현재 사용자가 관리자인지 확인
  const callerToken = context.auth.token;
  if (!callerToken.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can promote users to admin.'
    );
  }

  const { uid } = data;

  if (!uid || typeof uid !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The uid parameter is required and must be a string.'
    );
  }

  try {
    // Custom Claims 설정
    await admin.auth().setCustomUserClaims(uid, {
      admin: true,
      role: "admin",
    });

    // Firestore 사용자 문서 업데이트
    await admin.firestore().collection('users').doc(uid).update({
      role: 'admin',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`User ${uid} promoted to admin by ${context.auth.uid}`);

    return { 
      success: true,
      message: `User ${uid} has been promoted to admin.`
    };
  } catch (error) {
    console.error('Error promoting user to admin:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to promote user to admin.'
    );
  }
});

// 사용자 생성 시 기본 설정
export const onUserCreate = functions.auth.user().onCreate(async (user: admin.auth.UserRecord) => {
  try {
    // 기본 Custom Claims 설정
    await admin.auth().setCustomUserClaims(user.uid, {
      free: true,
      role: 'free_user',
    });

    // Firestore에 사용자 문서 생성
    await admin.firestore().collection('users').doc(user.uid).set({
      email: user.email,
      displayName: user.displayName || user.email?.split('@')[0] || '',
      role: 'free_user',
      subscription: {
        planType: 'free',
        isActive: true,
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        endDate: null,
        autoRenew: false,
      },
      usage: {
        bookmarks: 0,
        downloads: 0,
        apiCalls: 0,
        lastReset: admin.firestore.FieldValue.serverTimestamp(),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Default user document created for ${user.email}`);
  } catch (error) {
    console.error('Error creating user document:', error);
  }
});

// 프리미엄 업그레이드 함수
export const upgradeUserToPremium = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  // 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  // 관리자 권한 확인
  const callerToken = context.auth.token;
  if (!callerToken.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can upgrade users to premium.'
    );
  }

  const { uid } = data;

  if (!uid || typeof uid !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The uid parameter is required and must be a string.'
    );
  }

  try {
    // Custom Claims 업데이트
    await admin.auth().setCustomUserClaims(uid, {
      premium: true,
      role: 'premium_user',
      free: false,
    });

    // Firestore 문서 업데이트
    await admin.firestore().collection('users').doc(uid).update({
      role: 'premium_user',
      'subscription.planType': 'pro',
      'subscription.isActive': true,
      'subscription.startDate': admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`User ${uid} upgraded to premium by ${context.auth.uid}`);

    return { 
      success: true,
      message: `User ${uid} has been upgraded to premium.`
    };
  } catch (error) {
    console.error('Error upgrading user to premium:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to upgrade user to premium.'
    );
  }
});

// 월별 사용량 리셋 (매월 1일 실행)
export const resetMonthlyUsage = functions.pubsub
  .schedule('0 0 1 * *')
  .timeZone('Asia/Seoul')
  .onRun(async (context: functions.EventContext) => {
    const batch = admin.firestore().batch();
    const usersRef = admin.firestore().collection('users');

    try {
      const snapshot = await usersRef.get();

      snapshot.forEach(doc => {
        batch.update(doc.ref, {
          'usage.bookmarks': 0,
          'usage.downloads': 0,
          'usage.apiCalls': 0,
          'usage.lastReset': admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      console.log('Monthly usage reset completed for all users');
    } catch (error) {
      console.error('Error resetting monthly usage:', error);
    }
  });
