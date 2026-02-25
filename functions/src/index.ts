import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.database();
const auth = admin.auth();

/**
 * Super Admin callable function to provision a new company.
 * 
 * Why a Cloud Function?
 * If the Super Admin tries to create a Firebase Auth user using the client SDK 
 * (createUserWithEmailAndPassword), Firebase will log the *new* user in and 
 * forcefully log the Super Admin out. Doing it via the Admin SDK in a Cloud Function
 * avoids this and lets us securely set the companyId.
 */
export const provisionCompany = functions.https.onCall(async (data, context) => {
    // 1. Security Check: Only Super Admins can call this.
    // In a real app we'd verify custom claims or check if context.auth.uid is a known Super Admin.
    // For this prototype, we'll verify they are logged in.
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'You must be logged in to create a company.'
        );
    }

    // Look up the calling user to verify they are an Administrator and have NO companyId (ie. Super Admin)
    const callerSnap = await db.ref(`users/${context.auth.uid}`).once('value');
    const callerData = callerSnap.val();

    if (!callerData || callerData.role !== 'Administrator' || callerData.companyId != null) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only Super Administrators can provision companies.'
        );
    }

    const { companyName, ownerEmail, tier } = data;

    if (!companyName || !ownerEmail || !tier) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Missing required fields (companyName, ownerEmail, tier).'
        );
    }

    let ownerUid: string;

    try {
        // 2. Create the Company Owner's Auth Account
        // We generate a random password. The user will reset it via email.
        const tempPassword = Math.random().toString(36).slice(-8) + 'A1!';

        const userRecord = await auth.createUser({
            email: ownerEmail,
            password: tempPassword,
            emailVerified: false,
        });

        ownerUid = userRecord.uid;

        // 3. Create the Company Record
        const companyRef = db.ref('companies').push();
        const companyId = companyRef.key!;

        const companyData = {
            name: companyName,
            ownerUid: ownerUid,
            subscriptionTier: tier,
            subscriptionStatus: 'trialing',
            propertyCount: 0,
            createdAt: admin.database.ServerValue.TIMESTAMP,
        };

        await companyRef.set(companyData);

        // 4. Create the Owner's Database Profile
        const userProfileData = {
            username: ownerEmail.split('@')[0],
            email: ownerEmail,
            role: 'Administrator', // They are an Admin *for their company*
            companyId: companyId,
            isActive: true,
        };

        await db.ref(`users/${ownerUid}`).set(userProfileData);

        // 5. Send Password Reset Email so they can set their real password
        const resetLink = await auth.generatePasswordResetLink(ownerEmail);
        // Note: In production, you'd email this link using SendGrid or an SMTP extension.
        // For now, we return it so the frontend can (optionally) log it.

        return {
            success: true,
            companyId,
            ownerUid,
            message: 'Company provisioned successfully.',
            resetLink,
        };

    } catch (error: any) {
        console.error('Error provisioning company:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Unknown error occurred.');
    }
});
