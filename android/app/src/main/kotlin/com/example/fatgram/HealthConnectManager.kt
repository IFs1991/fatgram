package com.example.fatgram

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.annotation.NonNull
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.aggregate.AggregationResult
import androidx.health.connect.client.aggregate.AggregationResultGroupedByDuration
import androidx.health.connect.client.aggregate.AggregationResultGroupedByPeriod
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

/**
 * Health Connect統合を管理するAndroidネイティブクラス
 * Flutterアプリとの橋渡しを行い、Health Connect APIへのアクセスを提供
 */
class HealthConnectManager : FlutterPlugin, MethodCallHandler {

    companion object {
        private const val CHANNEL = "fatgram/health_connect"
        private const val TAG = "HealthConnectManager"

        // 権限定数
        private val REQUIRED_PERMISSIONS = setOf(
            HealthPermission.getReadPermission(ExerciseSessionRecord::class),
            HealthPermission.getWritePermission(ExerciseSessionRecord::class),
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(DistanceRecord::class)
        )
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var healthConnectClient: HealthConnectClient
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // Health Connect クライアントの初期化
        try {
            healthConnectClient = HealthConnectClient.getOrCreate(context)
            Log.d(TAG, "HealthConnect client initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize HealthConnect client", e)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "isAvailable" -> checkAvailability(result)
            "requestPermissions" -> requestPermissions(call, result)
            "isPermissionGranted" -> checkPermission(call, result)
            "readWorkouts" -> readWorkouts(call, result)
            "readHeartRateSamples" -> readHeartRateSamples(call, result)
            "readStepsSamples" -> readStepsSamples(call, result)
            "writeWorkout" -> writeWorkout(call, result)
            "enableBackgroundSync" -> enableBackgroundSync(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Health Connectの利用可能性をチェック
     */
    private fun checkAvailability(result: Result) {
        coroutineScope.launch {
            try {
                val availability = HealthConnectClient.getSdkStatus(context)
                when (availability) {
                    HealthConnectClient.SDK_AVAILABLE -> {
                        Log.d(TAG, "Health Connect is available")
                        result.success(true)
                    }
                    HealthConnectClient.SDK_UNAVAILABLE -> {
                        Log.d(TAG, "Health Connect is not available")
                        result.success(false)
                    }
                    HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> {
                        Log.d(TAG, "Health Connect requires provider update")
                        result.success(false)
                    }
                    else -> {
                        Log.d(TAG, "Health Connect availability unknown")
                        result.success(false)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking Health Connect availability", e)
                result.success(false)
            }
        }
    }

    /**
     * Health Connect権限をリクエスト
     */
    private fun requestPermissions(call: MethodCall, result: Result) {
        val permissions = call.argument<List<String>>("permissions") ?: emptyList()

        coroutineScope.launch {
            try {
                val permissionController = PermissionController.createRequestPermissionResultContract()

                // 権限状態を確認
                val grantedPermissions = healthConnectClient.permissionController.getGrantedPermissions()
                val hasAllPermissions = REQUIRED_PERMISSIONS.all { grantedPermissions.contains(it) }

                Log.d(TAG, "Permission request - Already granted: $hasAllPermissions")
                result.success(hasAllPermissions)
            } catch (e: Exception) {
                Log.e(TAG, "Error requesting permissions", e)
                result.success(false)
            }
        }
    }

    /**
     * 特定権限の状態をチェック
     */
    private fun checkPermission(call: MethodCall, result: Result) {
        val permission = call.argument<String>("permission") ?: ""

        coroutineScope.launch {
            try {
                val grantedPermissions = healthConnectClient.permissionController.getGrantedPermissions()
                val isGranted = when (permission) {
                    "android.permission.health.READ_EXERCISE" ->
                        grantedPermissions.contains(HealthPermission.getReadPermission(ExerciseSessionRecord::class))
                    "android.permission.health.READ_HEART_RATE" ->
                        grantedPermissions.contains(HealthPermission.getReadPermission(HeartRateRecord::class))
                    "android.permission.health.READ_STEPS" ->
                        grantedPermissions.contains(HealthPermission.getReadPermission(StepsRecord::class))
                    else -> false
                }

                Log.d(TAG, "Permission check for $permission: $isGranted")
                result.success(isGranted)
            } catch (e: Exception) {
                Log.e(TAG, "Error checking permission: $permission", e)
                result.success(false)
            }
        }
    }

    /**
     * ワークアウトデータを読み取り
     */
    private fun readWorkouts(call: MethodCall, result: Result) {
        val startTimeStr = call.argument<String>("startTime")
        val endTimeStr = call.argument<String>("endTime")

        coroutineScope.launch {
            try {
                val timeFilter = createTimeFilter(startTimeStr, endTimeStr)

                val request = ReadRecordsRequest(
                    recordType = ExerciseSessionRecord::class,
                    timeRangeFilter = timeFilter
                )

                val response = healthConnectClient.readRecords(request)
                val workouts = response.records.map { record ->
                    mapWorkoutToMap(record)
                }

                Log.d(TAG, "Successfully read ${workouts.size} workouts")
                result.success(workouts)
            } catch (e: Exception) {
                Log.e(TAG, "Error reading workouts", e)
                result.error("READ_ERROR", "Failed to read workouts: ${e.message}", null)
            }
        }
    }

    /**
     * 心拍数データを読み取り
     */
    private fun readHeartRateSamples(call: MethodCall, result: Result) {
        val startTimeStr = call.argument<String>("startTime")
        val endTimeStr = call.argument<String>("endTime")

        coroutineScope.launch {
            try {
                val timeFilter = createTimeFilter(startTimeStr, endTimeStr)

                val request = ReadRecordsRequest(
                    recordType = HeartRateRecord::class,
                    timeRangeFilter = timeFilter
                )

                val response = healthConnectClient.readRecords(request)
                val heartRateData = response.records.map { record ->
                    mapHeartRateToMap(record)
                }

                Log.d(TAG, "Successfully read ${heartRateData.size} heart rate records")
                result.success(heartRateData)
            } catch (e: Exception) {
                Log.e(TAG, "Error reading heart rate data", e)
                result.error("READ_ERROR", "Failed to read heart rate data: ${e.message}", null)
            }
        }
    }

    /**
     * ステップデータを読み取り
     */
    private fun readStepsSamples(call: MethodCall, result: Result) {
        val startTimeStr = call.argument<String>("startTime")
        val endTimeStr = call.argument<String>("endTime")

        coroutineScope.launch {
            try {
                val timeFilter = createTimeFilter(startTimeStr, endTimeStr)

                val request = ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = timeFilter
                )

                val response = healthConnectClient.readRecords(request)
                val stepsData = response.records.map { record ->
                    mapStepsToMap(record)
                }

                Log.d(TAG, "Successfully read ${stepsData.size} steps records")
                result.success(stepsData)
            } catch (e: Exception) {
                Log.e(TAG, "Error reading steps data", e)
                result.error("READ_ERROR", "Failed to read steps data: ${e.message}", null)
            }
        }
    }

    /**
     * ワークアウトデータを書き込み
     */
    private fun writeWorkout(call: MethodCall, result: Result) {
        val workoutData = call.argument<Map<String, Any>>("workout") ?: emptyMap()

        coroutineScope.launch {
            try {
                val exerciseRecord = createExerciseRecord(workoutData)

                healthConnectClient.insertRecords(listOf(exerciseRecord))

                Log.d(TAG, "Successfully wrote workout")
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error writing workout", e)
                result.error("WRITE_ERROR", "Failed to write workout: ${e.message}", null)
            }
        }
    }

    /**
     * バックグラウンド同期を有効化
     */
    private fun enableBackgroundSync(result: Result) {
        // Health Connectではバックグラウンド同期は自動的に処理される
        // ここではプレースホルダーとして実装
        Log.d(TAG, "Background sync is handled automatically by Health Connect")
        result.success(true)
    }

    // ===================
    // ヘルパーメソッド
    // ===================

    /**
     * 時間フィルターを作成
     */
    private fun createTimeFilter(startTimeStr: String?, endTimeStr: String?): TimeRangeFilter {
        return if (startTimeStr != null && endTimeStr != null) {
            val startTime = Instant.parse(startTimeStr)
            val endTime = Instant.parse(endTimeStr)
            TimeRangeFilter.between(startTime, endTime)
        } else {
            TimeRangeFilter.none()
        }
    }

    /**
     * ワークアウトレコードをMapに変換
     */
    private fun mapWorkoutToMap(record: ExerciseSessionRecord): Map<String, Any> {
        return mapOf(
            "recordType" to "ExerciseSessionRecord",
            "startTime" to record.startTime.toString(),
            "endTime" to record.endTime.toString(),
            "exerciseType" to mapExerciseTypeToString(record.exerciseType),
            "title" to (record.title ?: "Workout"),
            "totalEnergyBurned" to mapOf(
                "value" to 0.0, // TODO: 実際のカロリーデータを取得
                "unit" to "kilocalories"
            ),
            "totalDistance" to mapOf(
                "value" to 0.0, // TODO: 実際の距離データを取得
                "unit" to "meters"
            )
        )
    }

    /**
     * 心拍数レコードをMapに変換
     */
    private fun mapHeartRateToMap(record: HeartRateRecord): Map<String, Any> {
        return mapOf(
            "recordType" to "HeartRateRecord",
            "time" to record.time.toString(),
            "samples" to record.samples.map { sample ->
                mapOf(
                    "beatsPerMinute" to sample.beatsPerMinute,
                    "time" to sample.time.toString()
                )
            }
        )
    }

    /**
     * ステップレコードをMapに変換
     */
    private fun mapStepsToMap(record: StepsRecord): Map<String, Any> {
        return mapOf(
            "recordType" to "StepsRecord",
            "startTime" to record.startTime.toString(),
            "endTime" to record.endTime.toString(),
            "count" to record.count
        )
    }

    /**
     * Mapからエクササイズレコードを作成
     */
    private fun createExerciseRecord(workoutData: Map<String, Any>): ExerciseSessionRecord {
        val startTimeStr = workoutData["startTime"] as? String
        val endTimeStr = workoutData["endTime"] as? String
        val exerciseTypeStr = workoutData["exerciseType"] as? String
        val title = workoutData["title"] as? String

        val startTime = startTimeStr?.let { Instant.parse(it) } ?: Instant.now()
        val endTime = endTimeStr?.let { Instant.parse(it) } ?: Instant.now()
        val exerciseType = mapStringToExerciseType(exerciseTypeStr)

        return ExerciseSessionRecord(
            startTime = startTime,
            endTime = endTime,
            exerciseType = exerciseType,
            title = title
        )
    }

    /**
     * 運動タイプを文字列に変換
     */
    private fun mapExerciseTypeToString(exerciseType: Int): String {
        return when (exerciseType) {
            ExerciseSessionRecord.EXERCISE_TYPE_RUNNING -> "EXERCISE_TYPE_RUNNING"
            ExerciseSessionRecord.EXERCISE_TYPE_BIKING -> "EXERCISE_TYPE_BIKING"
            ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL -> "EXERCISE_TYPE_SWIMMING_POOL"
            ExerciseSessionRecord.EXERCISE_TYPE_WALKING -> "EXERCISE_TYPE_WALKING"
            ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING -> "EXERCISE_TYPE_STRENGTH_TRAINING"
            ExerciseSessionRecord.EXERCISE_TYPE_YOGA -> "EXERCISE_TYPE_YOGA"
            ExerciseSessionRecord.EXERCISE_TYPE_TENNIS -> "EXERCISE_TYPE_TENNIS"
            ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL -> "EXERCISE_TYPE_BASKETBALL"
            else -> "EXERCISE_TYPE_OTHER_WORKOUT"
        }
    }

    /**
     * 文字列を運動タイプに変換
     */
    private fun mapStringToExerciseType(exerciseTypeStr: String?): Int {
        return when (exerciseTypeStr) {
            "androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_RUNNING" ->
                ExerciseSessionRecord.EXERCISE_TYPE_RUNNING
            "androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_BIKING" ->
                ExerciseSessionRecord.EXERCISE_TYPE_BIKING
            "androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL" ->
                ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL
            "androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_WALKING" ->
                ExerciseSessionRecord.EXERCISE_TYPE_WALKING
            "androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING" ->
                ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING
            "androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_YOGA" ->
                ExerciseSessionRecord.EXERCISE_TYPE_YOGA
            "androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_TENNIS" ->
                ExerciseSessionRecord.EXERCISE_TYPE_TENNIS
            "androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL" ->
                ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL
            else -> ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT
        }
    }
}