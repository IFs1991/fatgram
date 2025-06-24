import * as admin from 'firebase-admin';
import * as request from 'supertest';
import {auth} from '../../src/api/auth';

// テストの初期化
describe('Auth API', () => {
  let app: any;
  let mockIdToken: string;
  let mockUser: any;

  beforeAll(async () => {
    // Firebase Admin初期化（テスト環境）
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: 'fatgram-test'
      });
    }

    app = auth; // Express app

    // モックユーザー作成
    mockUser = {
      uid: 'test-user-123',
      email: 'test@fatgram.com',
      displayName: 'Test User',
      subscriptionTier: 'free'
    };

    // モックトークン
    mockIdToken = 'mock-id-token';
  });

  afterAll(async () => {
    // クリーンアップ
    if (admin.apps.length) {
      await Promise.all(admin.apps.map(app => app.delete()));
    }
  });

  beforeEach(() => {
    // Firebase Admin モック
    jest.spyOn(admin.auth(), 'verifyIdToken').mockResolvedValue(mockUser as any);
    jest.spyOn(admin.auth(), 'getUser').mockResolvedValue({
      uid: mockUser.uid,
      email: mockUser.email,
      displayName: mockUser.displayName,
      photoURL: null,
      phoneNumber: null,
      emailVerified: true
    } as any);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('GET /profile', () => {
    it('should return user profile successfully', async () => {
      // Firestore モック
      const mockUserDoc = {
        exists: true,
        data: () => ({
          displayName: 'Test User',
          goals: {dailyFatBurn: 100},
          preferences: {notifications: true},
          stats: {totalActivities: 5}
        })
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc)
        })
      } as any);

      const response = await request(app)
          .get('/profile')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.uid).toBe(mockUser.uid);
      expect(response.body.data.email).toBe(mockUser.email);
      expect(response.body.data.subscriptionTier).toBe('free');
    });

    it('should return 401 for missing token', async () => {
      const response = await request(app)
          .get('/profile')
          .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Unauthorized: No token provided');
    });

    it('should return 404 for non-existent user', async () => {
      // User does not exist in Firestore
      const mockUserDoc = {
        exists: false,
        data: () => null
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockUserDoc)
        })
      } as any);

      const response = await request(app)
          .get('/profile')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(404);

      expect(response.body.error).toBe('User not found');
    });
  });

  describe('PUT /profile', () => {
    it('should update user profile successfully', async () => {
      const updateData = {
        displayName: 'Updated Name',
        height: 175,
        weight: 70,
        age: 30
      };

      // Firestore update モック
      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: jest.fn().mockResolvedValue(true)
        })
      } as any);

      // Firebase Auth update モック
      jest.spyOn(admin.auth(), 'updateUser').mockResolvedValue({} as any);

      const response = await request(app)
          .put('/profile')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(updateData)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Profile updated successfully');
    });

    it('should validate profile data', async () => {
      const invalidData = {
        height: -1, // Invalid negative height
        weight: 1000, // Invalid excessive weight
        age: 200 // Invalid age
      };

      const response = await request(app)
          .put('/profile')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(invalidData)
          .expect(400);

      expect(response.body.error).toBe('No valid fields to update');
    });

    it('should filter out unauthorized fields', async () => {
      const unauthorizedData = {
        displayName: 'Valid Name',
        uid: 'malicious-uid-change', // Should be filtered out
        adminFlag: true // Should be filtered out
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: jest.fn().mockResolvedValue(true)
        })
      } as any);

      jest.spyOn(admin.auth(), 'updateUser').mockResolvedValue({} as any);

      const response = await request(app)
          .put('/profile')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(unauthorizedData)
          .expect(200);

      // Verify only authorized fields were processed
      const firestoreCall = (admin.firestore().collection as jest.Mock).mock.calls[0];
      expect(firestoreCall[0]).toBe('users');
    });
  });

  describe('POST /update-claims', () => {
    it('should update subscription claims for admin', async () => {
      const adminUser = {
        ...mockUser,
        role: 'admin'
      };

      jest.spyOn(admin.auth(), 'verifyIdToken').mockResolvedValue(adminUser as any);
      jest.spyOn(admin.auth(), 'setCustomUserClaims').mockResolvedValue();

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: jest.fn().mockResolvedValue(true)
        })
      } as any);

      const claimsData = {
        subscriptionTier: 'premium'
      };

      const response = await request(app)
          .post('/update-claims')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(claimsData)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Claims updated successfully');
    });

    it('should deny non-admin access to custom claims', async () => {
      const regularUser = {
        ...mockUser,
        role: 'user'
      };

      jest.spyOn(admin.auth(), 'verifyIdToken').mockResolvedValue(regularUser as any);

      const claimsData = {
        customClaims: {
          role: 'admin' // Trying to escalate privileges
        }
      };

      const response = await request(app)
          .post('/update-claims')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(claimsData)
          .expect(403);

      expect(response.body.error).toBe('Forbidden: Admin required for custom claims');
    });
  });

  describe('POST /refresh-token', () => {
    it('should generate new custom token', async () => {
      const mockCustomToken = 'new-custom-token';

      jest.spyOn(admin.auth(), 'createCustomToken').mockResolvedValue(mockCustomToken);

      const response = await request(app)
          .post('/refresh-token')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.customToken).toBe(mockCustomToken);
    });

    it('should handle token creation errors', async () => {
      jest.spyOn(admin.auth(), 'createCustomToken').mockRejectedValue(new Error('Token creation failed'));

      const response = await request(app)
          .post('/refresh-token')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(500);

      expect(response.body.error).toBe('Internal server error');
    });
  });

  describe('DELETE /account', () => {
    it('should delete user account with password confirmation', async () => {
      jest.spyOn(admin.auth(), 'deleteUser').mockResolvedValue();

      const deleteData = {
        password: 'user-password'
      };

      const response = await request(app)
          .delete('/account')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(deleteData)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Account deleted successfully');
    });

    it('should require password for account deletion', async () => {
      const response = await request(app)
          .delete('/account')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send({})
          .expect(400);

      expect(response.body.error).toBe('Password required for account deletion');
    });
  });

  describe('GET /stats', () => {
    it('should return user statistics', async () => {
      const mockActivities = [
        {
          data: () => ({
            caloriesBurned: 250,
            durationInSeconds: 1800,
            timestamp: admin.firestore.Timestamp.now()
          })
        },
        {
          data: () => ({
            caloriesBurned: 300,
            durationInSeconds: 2100,
            timestamp: admin.firestore.Timestamp.now()
          })
        }
      ];

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: mockActivities
        })
      } as any);

      const response = await request(app)
          .get('/stats')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.total.activities).toBe(2);
      expect(response.body.data.total.caloriesBurned).toBe(550);
      expect(response.body.data.total.fatBurned).toBeCloseTo(73.15); // 550 * 0.133
    });

    it('should handle empty activity history', async () => {
      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: []
        })
      } as any);

      const response = await request(app)
          .get('/stats')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.total.activities).toBe(0);
      expect(response.body.data.averagePerWorkout).toBeNull();
    });
  });

  describe('Error Handling', () => {
    it('should handle Firebase Auth errors gracefully', async () => {
      jest.spyOn(admin.auth(), 'verifyIdToken').mockRejectedValue(new Error('Invalid token'));

      const response = await request(app)
          .get('/profile')
          .set('Authorization', `Bearer invalid-token`)
          .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Authentication failed');
    });

    it('should handle Firestore errors gracefully', async () => {
      jest.spyOn(admin.firestore(), 'collection').mockImplementation(() => {
        throw new Error('Firestore connection failed');
      });

      const response = await request(app)
          .get('/profile')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(500);

      expect(response.body.error).toBe('Internal server error');
    });
  });
});