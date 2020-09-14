//
// Created by wangliu on 2019-08-01.
//

#ifndef ANDROIDDEMO_BEF_EFFECT_AI_FACE_CLUSTERING_H
#define ANDROIDDEMO_BEF_EFFECT_AI_FACE_CLUSTERING_H

#if defined(__ANDROID__) || defined(TARGET_OS_ANDROID)
#include<jni.h>
#endif

#include "bef_effect_ai_public_define.h"

typedef enum {
    BEF_RecognitionfThreshold = 1, //人脸识别阈值，值越大，召回越高，默认值0.3
                                //Face recognition threshold, the higher the value, the higher the recall, the default value 0.3
    BEF_FeatureDim = 2,            //特征长度,默认为512
                                //Feature length, default to 512
    BEF_ClustingThreshold = 3,     //聚类时，两个临时类被合并的距离阈值 越小约准，但是越不全，容易漏掉同一个人差异比较大的脸,越大越全，但是越不准，容易把不是同一人但是相似的脸聚进来
                                //In clustering, the smaller the distance threshold between two temporary classes is,
                                // but the less complete it is, and the more likely it is to miss the faces of the same person with large differences.
                                // The larger the more complete it is, but the less accurate it is, and the more likely it is to bring in the faces of similar people who are not the same person
    // 默认值dist_threshold = 1.11 * 0.82;
            BEF_LinkageType = 4,           // Link method, default AvgLinkage； 链接方法,默认AvgLinkage
    BEF_DistanceType = 5,          // Distance measure method default Consine 距离度量方法 默认Consine
    BEF_HP1 = 6,                   // Super parameter 1, default 0.765; 超参1, 默认0.765;
    BEF_HP2 = 7                  // Superparameter 2, default 0.178； 超参2,默认0.178

} bef_ai_fc_param_type;

typedef enum {
    BEF_EUCLIDEAN = 1,       //Euclidean distance 欧式距离
    BEF_COSINE = 2,          //Cosine distance, default 余弦距离, 默认值
    BEF_BHATTACHARYYAH = 3,  //Pap distance
}bef_ai_fc_distance_type;

typedef enum {
    BEF_AVERAGE_LINKAGE = 1,  /* choose average distance  default*/
    BEF_CENTROID_LINKAGE = 2, /* choose distance between cluster centroids */
    BEF_COMPLETE_LINKAGE = 3, /* choose maximum distance */
    BEF_SINGLE_LINKAGE = 4,   /* choose minimum distance */
}bef_ai_fc_link_type;


typedef struct {
    int * ids;
    int num;
}bef_ai_fc_node;

typedef struct {
    bef_ai_fc_node * cluster;
    int clusters;
}bef_ai_fc_cluster;


/**
 * @brief           Create a face clustering handle 创建人脸聚类句柄
 * @param handle    the face clustering handle created 创建的人脸聚类句柄
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_ai_public_define.h
 *         成功返回 BEF_RESULT_SUC, 失败返回相应错误码, 具体请参考 bef_effect_ai_public_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_ai_fc_create(bef_effect_handle_t *handle);

/**
 * @brief Face clustering parameter 人脸聚类参数设置
 * @param handle the face clustering handle 人脸聚类句柄
 * @param type param type 参数类型
 * @param value 参数值
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_ai_public_define.h
 *         成功返回 BEF_RESULT_SUC, 失败返回相应错误码, 具体请参考 bef_effect_ai_public_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_ai_fc_set_param(bef_effect_handle_t handle, bef_ai_fc_param_type type, float value);

/**
 *@brief Face feature clustering 人脸特征聚类
 *@param features         Face features, size is num_samples * FACE_FEATURE_DIM
 *                  人脸特征，大小为 num_samples * FACE_FEATURE_DIM
 *@param num_samples      Number of faces 人脸的数量
 *@param clusters         Output face clustering results 输出的人脸聚类结果
 */

BEF_SDK_API bef_effect_result_t  bef_effect_ai_fc_do_clustering(bef_effect_handle_t handle,
                                                                    float *const features,
                                                                 const int num_samples,
                                                                int *clusters);
/**
 * 释放人脸聚类句柄
 * @param handle
 * @return
 */
BEF_SDK_API bef_effect_result_t bef_effect_ai_fc_release(bef_effect_handle_t handle);


/**
 * @brief Face clustering authorization 人脸聚类授权
 * @param [in] handle Created face detect handle
 *                    已创建的人脸聚类句柄
 * @param [in] license license file path 授权文件字符串
 * @param [in] length  length of license file path 授权文件字符串长度
 * @return If succeed return BEF_RESULT_SUC, other value please refer bef_effect_ai_public_define.h
 *         成功返回 BEF_RESULT_SUC, 授权码非法返回 BEF_RESULT_INVALID_LICENSE ，其它失败返回相应错误码, 具体请参考 bef_effect_ai_public_define.h
 */
#if defined(__ANDROID__) || defined(TARGET_OS_ANDROID)
BEF_SDK_API bef_effect_result_t bef_effect_ai_face_cluster_check_license(JNIEnv *env, jobject context,
                                                                 bef_effect_handle_t handle,
                                                                 const char *licensePath);
#else
#ifdef __APPLE__
BEF_SDK_API bef_effect_result_t bef_effect_ai_face_cluster_check_license(bef_effect_handle_t handle, const char *licensePath);
#endif
#endif


#endif //ANDROIDDEMO_BEF_EFFECT_AI_FACE_CLUSTERING_H
