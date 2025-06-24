import * as admin from 'firebase-admin';
import * as request from 'supertest';
import {activities} from '../../src/api/activities';

// テストの初期化
describe('Activities API', () => {
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

    app = activities; // Express app

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
    jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      offset: jest.fn().mockReturnThis(),
      get: jest.fn(),
      add: jest.fn(),
      doc: jest.fn()
    } as any);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('GET /', () => {
    it('should return activities list with pagination', async () => {
      const mockActivities = [
        {
          id: 'activity-1',
          data: () => ({
            userId: mockUser.uid,
            type: 'running',
            timestamp: admin.firestore.Timestamp.now(),
            durationInSeconds: 1800,
            caloriesBurned: 300,
            distanceInMeters: 5000
          })
        },
        {
          id: 'activity-2',
          data: () => ({
            userId: mockUser.uid,
            type: 'cycling',
            timestamp: admin.firestore.Timestamp.now(),
            durationInSeconds: 2400,
            caloriesBurned: 400,
            distanceInMeters: 15000
          })
        }
      ];

      const mockSnapshot = {
        docs: mockActivities
      };

      const mockCountSnapshot = {
        data: () => ({count: 25})
      };

      // Firestore クエリのモック
      const mockCollection = {
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        offset: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(mockSnapshot),
        count: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockCountSnapshot)
        })
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue(mockCollection as any);

      const response = await request(app)
          .get('/?limit=20&offset=0&sortBy=timestamp&sortOrder=desc')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.activities).toHaveLength(2);
      expect(response.body.data.pagination.total).toBe(25);
      expect(response.body.data.pagination.hasMore).toBe(true);
    });

    it('should filter activities by type', async () => {
      const mockCollection = {
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        offset: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({docs: []}),
        count: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({data: () => ({count: 0})})
        })
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue(mockCollection as any);

      const response = await request(app)
          .get('/?type=running')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(mockCollection.where).toHaveBeenCalledWith('type', '==', 'running');
      expect(response.body.success).toBe(true);
    });

    it('should filter activities by date range', async () => {
      const mockCollection = {
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        offset: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({docs: []}),
        count: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({data: () => ({count: 0})})
        })
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue(mockCollection as any);

      const startDate = '2024-01-01';
      const endDate = '2024-01-31';

      const response = await request(app)
          .get(`/?startDate=${startDate}&endDate=${endDate}`)
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(mockCollection.where).toHaveBeenCalledWith('timestamp', '>=', expect.any(admin.firestore.Timestamp));
      expect(mockCollection.where).toHaveBeenCalledWith('timestamp', '<=', expect.any(admin.firestore.Timestamp));
      expect(response.body.success).toBe(true);
    });
  });

  describe('GET /:id', () => {
    it('should return single activity', async () => {
      const mockActivity = {
        userId: mockUser.uid,
        type: 'swimming',
        timestamp: admin.firestore.Timestamp.now(),
        durationInSeconds: 3600,
        caloriesBurned: 500,
        distanceInMeters: 2000
      };

      const mockDoc = {
        exists: true,
        id: 'activity-123',
        data: () => mockActivity
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockDoc)
        })
      } as any);

      const response = await request(app)
          .get('/activity-123')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe('activity-123');
      expect(response.body.data.type).toBe('swimming');
    });

    it('should return 404 for non-existent activity', async () => {
      const mockDoc = {
        exists: false,
        data: () => null
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockDoc)
        })
      } as any);

      const response = await request(app)
          .get('/non-existent-id')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(404);

      expect(response.body.error).toBe('Activity not found');
    });

    it('should return 403 for unauthorized access', async () => {
      const mockActivity = {
        userId: 'other-user-id', // Different user
        type: 'running'
      };

      const mockDoc = {
        exists: true,
        data: () => mockActivity
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockDoc)
        })
      } as any);

      const response = await request(app)
          .get('/activity-123')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(403);

      expect(response.body.error).toBe('Forbidden: Access denied');
    });
  });

  describe('POST /', () => {
    it('should create new activity successfully', async () => {
      const newActivity = {
        type: 'workout',
        timestamp: new Date().toISOString(),
        durationInSeconds: 2700,
        caloriesBurned: 350,
        distanceInMeters: 0,
        metadata: {
          exerciseType: 'strength training'
        }
      };

      const mockDocRef = {
        id: 'new-activity-id'
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        add: jest.fn().mockResolvedValue(mockDocRef)
      } as any);

      const response = await request(app)
          .post('/')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(newActivity)
          .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe('new-activity-id');
      expect(response.body.data.userId).toBe(mockUser.uid);
    });

    it('should validate required fields', async () => {
      const invalidActivity = {
        type: 'running'
        // Missing required fields
      };

      const response = await request(app)
          .post('/')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(invalidActivity)
          .expect(400);

      expect(response.body.error).toContain('Missing required field');
    });

    it('should validate negative values', async () => {
      const invalidActivity = {
        type: 'running',
        timestamp: new Date().toISOString(),
        durationInSeconds: -100, // Invalid negative duration
        caloriesBurned: -50      // Invalid negative calories
      };

      const response = await request(app)
          .post('/')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(invalidActivity)
          .expect(400);

      expect(response.body.error).toBe('Duration and calories must be non-negative');
    });
  });

  describe('PUT /:id', () => {
    it('should update activity successfully', async () => {
      const mockActivity = {
        userId: mockUser.uid,
        type: 'running',
        caloriesBurned: 300
      };

      const mockDoc = {
        exists: true,
        data: () => mockActivity
      };

      const updateData = {
        caloriesBurned: 350,
        durationInSeconds: 2000
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockDoc),
          update: jest.fn().mockResolvedValue(true)
        })
      } as any);

      const response = await request(app)
          .put('/activity-123')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(updateData)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Activity updated successfully');
    });

    it('should validate update data', async () => {
      const mockActivity = {
        userId: mockUser.uid,
        type: 'running'
      };

      const mockDoc = {
        exists: true,
        data: () => mockActivity
      };

      const invalidUpdateData = {
        durationInSeconds: -500 // Invalid negative value
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockDoc)
        })
      } as any);

      const response = await request(app)
          .put('/activity-123')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .send(invalidUpdateData)
          .expect(400);

      expect(response.body.error).toBe('Duration must be non-negative');
    });
  });

  describe('DELETE /:id', () => {
    it('should delete activity successfully', async () => {
      const mockActivity = {
        userId: mockUser.uid,
        type: 'running'
      };

      const mockDoc = {
        exists: true,
        data: () => mockActivity
      };

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(mockDoc),
          delete: jest.fn().mockResolvedValue(true)
        })
      } as any);

      const response = await request(app)
          .delete('/activity-123')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Activity deleted successfully');
    });
  });

  describe('GET /stats/summary', () => {
    it('should return activity statistics', async () => {
      const mockActivities = [
        {
          data: () => ({
            type: 'running',
            caloriesBurned: 300,
            durationInSeconds: 1800,
            distanceInMeters: 5000,
            timestamp: admin.firestore.Timestamp.now()
          })
        },
        {
          data: () => ({
            type: 'cycling',
            caloriesBurned: 400,
            durationInSeconds: 2400,
            distanceInMeters: 15000,
            timestamp: admin.firestore.Timestamp.now()
          })
        }
      ];

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({docs: mockActivities})
      } as any);

      const response = await request(app)
          .get('/stats/summary?period=week')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.total.activities).toBe(2);
      expect(response.body.data.total.caloriesBurned).toBe(700);
      expect(response.body.data.total.fatBurned).toBeCloseTo(93.1); // 700 * 0.133
      expect(response.body.data.byType).toHaveProperty('running');
      expect(response.body.data.byType).toHaveProperty('cycling');
    });
  });

  describe('GET /stats/trends', () => {
    it('should return weekly trends', async () => {
      const mockActivities = [
        {
          data: () => ({
            caloriesBurned: 250,
            durationInSeconds: 1500,
            timestamp: admin.firestore.Timestamp.now()
          })
        }
      ];

      jest.spyOn(admin.firestore(), 'collection').mockReturnValue({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({docs: mockActivities})
      } as any);

      const response = await request(app)
          .get('/stats/trends?days=30')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.period).toBe('30 days');
      expect(response.body.data.weeklyTrends).toBeDefined();
    });
  });

  describe('Error Handling', () => {
    it('should handle Firestore errors gracefully', async () => {
      jest.spyOn(admin.firestore(), 'collection').mockImplementation(() => {
        throw new Error('Firestore connection failed');
      });

      const response = await request(app)
          .get('/')
          .set('Authorization', `Bearer ${mockIdToken}`)
          .expect(500);

      expect(response.body.error).toBe('Internal server error');
    });

    it('should require authentication', async () => {
      const response = await request(app)
          .get('/')
          .expect(401);

      expect(response.body.error).toBe('Unauthorized: No token provided');
    });
  });
});