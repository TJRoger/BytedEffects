// Copyright (C) 2019 Beijing Bytedance Network Technology Co., Ltd.
#ifndef _BEF_EFFECT_FACE_ATTRIBUTE_H_
#define _BEF_EFFECT_FACE_ATTRIBUTE_H_

#if defined(__ANDROID__) || defined(TARGET_OS_ANDROID)
#include<jni.h>
#endif

#include "bef_effect_ai_public_define.h"
#include "bef_effect_ai_face_detect.h"

typedef enum {
  BEF_FACE_ATTRIBUTE_AGE          = 0x00000001,     //age 年龄
  BEF_FACE_ATTRIBUTE_GENDER       = 0x00000002,     //sex 性别
  BEF_FACE_ATTRIBUTE_EXPRESSION   = 0x00000004,     //expression 表情
  BEF_FACE_ATTRIBUTE_ATTRACTIVE   = 0x00000008,     //Level of appearance 颜值
  BEF_FACE_ATTRIBUTE_HAPPINESS    = 0x00000010,     //The degree of happy 开心程度
  BEF_FACE_ATTRIBUTE_RACIAL       = 0x00000020,     //Color of skin 肤色
} bef_ai_face_attribute_types;

typedef enum {
  BEF_FACE_ATTRIBUTE_ForceDetect = 0x10000000,     //未加平滑的裸数据，重置缓存，在切换摄像头时等上下帧剧烈变化时使用
                                                  //Unsmoothed naked data, reset cache, used when the frame changes dramatically during switching camera
                                //用于处理切换摄像头，跟踪的人脸ID 混淆的问题
                                //Used to handle tracking face ID confusion when switching camera
} bef_ai_face_attribut_config;

/*
 *@brief Enumeration of skin color classes 肤色类别枚举
**/
typedef enum {
  BEF_FACE_ATTRIBUTE_WHITE = 0,                   //white 白种人
  BEF_FACE_ATTRIBUTE_YELLOW = 1,                  //yellow 黄种人
  BEF_FACE_ATTRIBUTE_INDIAN = 2,                  //indian 印度人
  BEF_FACE_ATTRIBUTE_BLACK = 3,                   //black 黑种人
  BEF_FACE_ATTRIBUTE_NUM_RACIAL = 4,              //Number of skin types supported 支持的肤色个数
}bef_ai_face_attribute_racial_type;

/*
 *@brief 表情类别枚举
**/
typedef enum {
  BEF_FACE_ATTRIBUTE_ANGRY = 0,                   //angry 生气
  BEF_FACE_ATTRIBUTE_DISGUST = 1,                 //hate 厌恶
  BEF_FACE_ATTRIBUTE_FEAR = 2,                    //afraid 害怕
  BEF_FACE_ATTRIBUTE_HAPPY = 3,                   //happy 高兴
  BEF_FACE_ATTRIBUTE_SAD = 4,                     //sad 伤心
  BEF_FACE_ATTRIBUTE_SURPRISE = 5,                //surprised 吃惊
  BEF_FACE_ATTRIBUTE_NEUTRAL = 6,                 //calm 平静
  BEF_FACE_ATTRIBUTE_NUM_EXPRESSION = 7           //Number of supported emoticons 支持的表情个数
}bef_ai_face_attribute_expression_type;

/*
 *@breif 单个人脸属性结构体
**/
typedef struct bef_ai_face_attribute_info {
  float age;                          // Predicted age, value between 0-100  预测的年龄值， 值范围【0，100】之间
  float boy_prob;                     // The probability of predicting male, value between 0.0 - 1.0 预测为男性的概率值，值范围【0.0，1.0】之间
  float attractive;                   // Predicted appearance level scores, value between 0-100 预测的颜值分数，范围【0，100】之间
  float happy_score;                  // Predicted degress of smiles, value between 0-100 预测的微笑程度，范围【0，100】之间
  bef_ai_face_attribute_expression_type exp_type;            // Predicted expression categories 预测的表情类别
  float exp_probs[BEF_FACE_ATTRIBUTE_NUM_EXPRESSION];    // Predicted the probability of each expression, without smoothing 预测的每个表情的概率，未加平滑处理
  bef_ai_face_attribute_racial_type racial_type;             // Predicted skin color category 预测的肤色类别
  float racial_probs[BEF_FACE_ATTRIBUTE_NUM_RACIAL];     // Predict the probability of each skin color category without smoothing 预测的每个类别肤色的概率，未加平滑处理
  // The following are reserved fields that currently have no value returned 以下属于预留字段 目前没有值返回
  float real_face_prob;               // Predict the probability of belonging to the real face, which can be used to distinguish non-real faces such as sculptures and cartoons
                                      // 预测属于真人脸的概率，用于区分雕塑、漫画等非真实人脸
  float quality;                      // Predict the mass fraction of a face,between 0-100 预测人脸的质量分数，范围【0，100】之间
  float arousal;                      // The intensity of the emotion 情绪的强烈程度
  float valence;                      // The degree to which emotions are positive or negative 情绪的正负情绪程度
  float sad_score;                    // The degree of sad 伤心程度
  float angry_score;                  // The degree of angry 生气程度
  float surprise_score;               // The degree of surprised 吃惊的程度
  float mask_prob;                    // The probability of wearing a mask 预测带口罩的概率
  float wear_hat_prob;                // The probability of wearing a hat 戴帽子的概率
  float mustache_prob;                // The probability of having a beard 有胡子的概率
  float lipstick_prob;                // Probability of lipstick 涂口红的概率
  float wear_glass_prob;              // The probability of wearing normal glasses 带普通眼镜的概率
  float wear_sunglass_prob;           // The probability of wearing sunglasses 带墨镜的概率
  float blur_score;                   // The fuzzy degree of 模糊程度
  float illumination;                 // Degree of light 光照
} bef_ai_face_attribute_info;


typedef enum {
  // 身份相关的属性(性别、年龄、肤色)检测隔帧数，默认值为12;
  // The number of frames detected for identity-related attributes (gender, age, skin color) is 12 by default.
  BEF_FACE_ATTRIBUTE_IDRelatedDetectInterval = 1,
  // 非身份相关的属性(表情、颜值、微笑程度）检测隔帧数，默认值为1，即每帧都识别；
  // 保留字段，当前不可设；
  // Non-identity-related attributes (expression, appearance level, smile degree) detect the number of frames, the default value is 1, that is, each frame is recognized;
  // Reserved field, not currently set;
  BEF_FACE_ATTRIBUTE_DetectInterval = 2,
  // 当身份相关的属性识别置信度足够高时，停止计算该属性（结果在SDK中存储中正常返回，对外不感知）
  // 默认值为1，表示打开，设置为0,表示关闭；
  // When the identification confidence of identity-related attribute is high enough,
  // the calculation of this attribute will be stopped (the result will be returned normally in the SDK without external awareness).
  // The default value is 1, which means open, set to 0, which means close;
  BEF_FACE_ATTRIBUTE_IDRelatedAccumulateResult = 3,
}bef_ai_face_attribute_param_config_type;

/*
 *@brief Multiple face attribute structures 多个人脸属性结构体
 *@param
 *      face_count valid number of faces 有效的人脸个数
**/
typedef struct bef_ai_face_attribute_result {
  bef_ai_face_attribute_info  attr_info[BEF_MAX_FACE_NUM];    //Store the result array of face properties 存放人脸属性结果数组
  int face_count;                         //valid number of faces，That means the preceding face_count individual face in attr_info is valid
                                          // 有效的人脸个数，即表示attr_info中的前face_count个人脸是有效的
} bef_ai_face_attribute_result;



/**
 * @brief Creates a handle to face property detection
 *          创建人脸属性检测的句柄
 * @param [in] config Config of face attribute detect algorithm
 *                    人脸属性检测算法的配置
 * @param [in] strModelPath The path where the model file is located
 *                      模型文件所在路径
 * @param [out] handle Created face attribute detect handle
 *                     创建的人脸属性检测句柄
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 *         成功返回 BEF_RESULT_SUC, 失败返回相应错误码, 具体请参考 bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_ai_face_attribute_create(
  unsigned long long config,
  const char * strModelPath,
  bef_effect_handle_t *handle
);

/**
 * @brief   Single face attribute detection
 *          单个人脸属性检测
 * @param [in] handle Created face attribute detect handle
 *                    已创建的人脸属性检测句柄
 * @param [in] image Image base address
 *                   输入图片的数据指针
 * @param [in] pixel_format Pixel format of input image
 *                          输入图片的格式
 * @param [in] image_width  Image width
 *                          输入图像的宽度 (以像素为单位)
 * @param [in] image_height Image height
 *                          输入图像的高度 (以像素为单位)
 * @param [in] image_stride Image stride in each row
 *                          输入图像每一行的步长 (以像素为单位)
 * @param [in] ptr_base_info 人脸检测结果
 * @param [in] detect_config Config of face detect, for example
 *                           人脸检测相关的配置
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 *         成功返回 BEF_RESULT_SUC, 失败返回相应错误码, 具体请参考 bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_ai_face_attribute_detect(
  bef_effect_handle_t handle,
  const unsigned char *image,
  bef_ai_pixel_format pixel_format,
  int image_width,
  int image_height,
  int image_stride,
  const bef_ai_face_106 *ptr_base_info,
  unsigned long long config,
  bef_ai_face_attribute_info *ptr_face_attribute_info
);

/**
 * @brief 多个人脸属性检测
 *          Multiple face attribute detection
 * @param [in] handle Created face attribute detect handle
 *                    已创建的人脸属性检测句柄
 * @param [in] image Image base address
 *                   输入图片的数据指针
 * @param [in] pixel_format Pixel format of input image
 *                          输入图片的格式
 * @param [in] image_width  Image width
 *                          输入图像的宽度 (以像素为单位)
 * @param [in] image_height Image height
 *                          输入图像的高度 (以像素为单位)
 * @param [in] image_stride Image stride in each row
 *                          输入图像每一行的步长 (以像素为单位)
 * @param [in] ptr_base_info 人脸检测结果
 * @param [in] face_count 人脸检测人脸数
 * @param [in] detect_config Config of face detect, for example
 *                           人脸检测相关的配置
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 *         成功返回 BEF_RESULT_SUC, 失败返回相应错误码, 具体请参考 bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_ai_face_attribute_detect_batch(
  bef_effect_handle_t handle,
  const unsigned char *image,
  bef_ai_pixel_format pixel_format,
  int image_width,
  int image_height,
  int image_stride,
  const bef_ai_face_106 *ptr_base_info,
  int face_count,
  unsigned long long config,
  bef_ai_face_attribute_result *ptr_face_attribute_result
);


/**
 * @brief Set face attribute detect parameter based on type 
 *     设置人脸属性检测的相关参数
 * @param [in] handle Created face detect handle
 *                    已创建的人脸检测句柄
 * @param [in] type Face detect type that needs to be set, check bef_face_detect_type for the detailed
 *                  需要设置的人体检测类型，可参考 bef_face_detect_type
 * @param [in] value Type value, check bef_face_detect_type for the detailed
 *                   参数值, 具体请参数 bef_face_detect_type 枚举中的说明
 * @return If succeed return BEF_RESULT_SUC, other value please refer bef_effect_base_define.h
 *         成功返回 BEF_RESULT_SUC, 失败返回相应错误码, 具体请参考 bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_ai_face_attribute_setparam(
  bef_effect_handle_t handle,
  bef_ai_face_attribute_param_config_type type,
  float value
);


/**
 * @param [in] handle Destroy the created face attribute detect handle
 *                    销毁创建的人脸属性检测句柄
 */
BEF_SDK_API void
bef_effect_ai_face_attribute_destroy(
  bef_effect_handle_t handle
);

/**
 * @brief   Face attribute detection authorization
 *          人脸属性检测授权
 * @param [in] handle Created face attribute detect handle
 *                    已创建的人脸检测句柄
 * @param [in] license License file path 授权文件字符串
 * @param [in] length  length of license file path授权文件字符串长度
 * @return If succeed return BEF_RESULT_SUC, other value please refer bef_effect_ai_public_define.h
 *         成功返回 BEF_RESULT_SUC, 授权码非法返回 BEF_RESULT_INVALID_LICENSE ，其它失败返回相应错误码, 具体请参考 bef_effect_ai_public_define.h
 */
#if defined(__ANDROID__) || defined(TARGET_OS_ANDROID)
BEF_SDK_API bef_effect_result_t bef_effect_ai_face_attribute_check_license(JNIEnv* env,
        jobject context, bef_effect_handle_t handle, const char *licensePath);
#else
#ifdef __APPLE__
BEF_SDK_API bef_effect_result_t bef_effect_ai_face_attribute_check_license(bef_effect_handle_t handle,
        const char *licensePath);
#endif
#endif


#endif // _BEF_EFFECT_FACE_DETECT_AI_H_
