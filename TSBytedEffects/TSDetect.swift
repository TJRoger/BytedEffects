//
//  TSDetect.swift
//  BytedEffectsDemo
//
//  Created by Roger Luo on 4/3/20.
//  Copyright © 2020 Roger Luo. All rights reserved.
//

import Foundation

class TSDetect: NSObject {
    static var LICENSE_PATH: String = "/yuban_test_20200331_20200415_com.mikasa.Moe-dev2_yuban_test_v3.8.2.licbag"
    let FACE_MODEL = "/ttfacemodel/tt_face_v6.0.model"
    let FACE_ATTRIBUTE_MODEL = "/ttfaceattri/tt_face_attribute_v4.1.model"
    
    var width: Int32 = 0, height: Int32 = 0, bytesPerRow: Int32 = 0
    var faceDetectHandle: bef_effect_handle_t?
    var faceAttributeDetectHandle: bef_effect_handle_t?
    
    // MARK: - util
    func getLicensePath() -> String? {
        let licenseBundle = getPath(name: "LicenseBag")
        return licenseBundle ?? "" + TSDetect.LICENSE_PATH
    }
    
    func getModelDir() -> String? {
        return getPath(name: "ModelResource")
    }
    
    func getPath(name: String?, type: String? = "bundle") -> String? {
        return Bundle.main.path(forResource: name, ofType: type)
    }
    
    func setSDK(width: Int32, height: Int32, bytesPerRow bytes: Int32) {
        self.width = width
        self.height = height
        self.bytesPerRow = bytes
    }
    
    func setupBytedEffectsSDK(path: String = TSDetect.LICENSE_PATH) {
        TSDetect.LICENSE_PATH = path
        self.setupFaceModel()
    }
    
    func setupFaceModel() {
        guard let resourceBundleName = getModelDir(), let licbag = getLicensePath() else {
            return
        }
        let faceModel = resourceBundleName + FACE_MODEL
        let faceAttributeModel = resourceBundleName + FACE_ATTRIBUTE_MODEL
        // 人脸检测初始化，传入算法模型文件路径
        // 这里使用了BEF_DETECT_FULL，因此会加载嘟嘴和眨眼模块
        var result = bef_effect_ai_face_detect_create(UInt64(BEF_DETECT_SMALL_MODEL | BEF_DETECT_FULL | BEF_DETECT_MODE_VIDEO), faceModel, &faceDetectHandle)
        if result != BEF_RESULT_SUC {
            print("byted_effect_face_detect_create error: \(result)")
        }
        
        // 检查人脸检测license
        result = bef_effect_ai_face_check_license(faceDetectHandle, licbag)
        if (result != BEF_RESULT_SUC) {
            print("bef_effect_ai_face_check_license error: %d", result);
        }
        
        result = bef_effect_ai_face_detect_setparam(faceDetectHandle, BEF_FACE_PARAM_FACE_DETECT_INTERVAL, 15);
        if (result != BEF_RESULT_SUC) {
            NSLog("byted_effect_face_detect_setparam error: %d", result);
        }
        
        result = bef_effect_ai_face_detect_setparam(faceDetectHandle, BEF_FACE_PARAM_MAX_FACE_NUM, 10);
        if (result != BEF_RESULT_SUC) {
            NSLog("byted_effect_face_detect_setparam error: %d", result);
        }
        // 人脸属性检测模型
        result = bef_effect_ai_face_attribute_create(0, faceAttributeModel, &faceAttributeDetectHandle);
        if (result != BEF_RESULT_SUC) {
            NSLog("byted_effect_face_ai_attribute_model error: %d", result);
        }
        // 人脸检测模型license
        result = bef_effect_ai_face_attribute_check_license(faceAttributeDetectHandle, licbag)
        if result != BEF_RESULT_SUC {
             NSLog("bef_effect_ai_face_attribute_check_license error: %d", result);
        }
    }
    
    func releaseBytedEffects() {
        TSDetect.LICENSE_PATH = ""
        bef_effect_ai_face_attribute_destroy(faceAttributeDetectHandle)
        bef_effect_ai_face_detect_destroy(faceDetectHandle)
    }
    
    func faceDetect(faceInfo: UnsafeMutablePointer<bef_ai_face_info>, buffer: UnsafePointer<UInt8>, format: bef_ai_pixel_format, orientation: bef_ai_rotate_type) {
        let result = bef_effect_ai_face_detect(faceDetectHandle, buffer, format, width, height, bytesPerRow, orientation, UInt64(BEF_DETECT_MODE_VIDEO | BEF_DETECT_FULL), faceInfo)
        
        if (result != BEF_RESULT_SUC){
            NSLog("bef_effect_ai_face_detect error: %d", result);
        }
    }
    
    func faceAttribteDetect(faceAttributeInfo: UnsafeMutablePointer<bef_ai_face_attribute_info>, buffer: UnsafePointer<UInt8>, faceInfo: UnsafePointer<bef_ai_face_106>, format: bef_ai_pixel_format ) {
        let attributeConfig = BEF_FACE_ATTRIBUTE_AGE.rawValue | BEF_FACE_ATTRIBUTE_HAPPINESS.rawValue | BEF_FACE_ATTRIBUTE_EXPRESSION.rawValue | BEF_FACE_ATTRIBUTE_GENDER.rawValue | BEF_FACE_ATTRIBUTE_RACIAL.rawValue | BEF_FACE_ATTRIBUTE_ATTRACTIVE.rawValue
        // 单个人脸检测
//        bef_effect_ai_face_attribute_detect(<#T##handle: bef_effect_handle_t!##bef_effect_handle_t!#>, <#T##image: UnsafePointer<UInt8>!##UnsafePointer<UInt8>!#>, <#T##pixel_format: bef_ai_pixel_format##bef_ai_pixel_format#>, <#T##image_width: Int32##Int32#>, <#T##image_height: Int32##Int32#>, <#T##image_stride: Int32##Int32#>, <#T##ptr_base_info: UnsafePointer<bef_ai_face_106>!##UnsafePointer<bef_ai_face_106>!#>, <#T##config: UInt64##UInt64#>, <#T##ptr_face_attribute_info: UnsafeMutablePointer<bef_ai_face_attribute_info>!##UnsafeMutablePointer<bef_ai_face_attribute_info>!#>)
        let result = bef_effect_ai_face_attribute_detect(faceAttributeDetectHandle, buffer, format, width, height, bytesPerRow, faceInfo, UInt64(attributeConfig), faceAttributeInfo)
        if result != BEF_RESULT_SUC {
            print("bef_effect_ai_face_attribute_detect error: %d", result)
        }
    }
    
    func faceAttributeDetect(faceAttributeResult: UnsafeMutablePointer<bef_ai_face_attribute_result>, buffer: UnsafePointer<UInt8>, faceInfo: UnsafePointer<bef_ai_face_106>, faceCount: Int32, format: bef_ai_pixel_format ) {
        let attributeConfig = BEF_FACE_ATTRIBUTE_AGE.rawValue | BEF_FACE_ATTRIBUTE_HAPPINESS.rawValue | BEF_FACE_ATTRIBUTE_EXPRESSION.rawValue | BEF_FACE_ATTRIBUTE_GENDER.rawValue | BEF_FACE_ATTRIBUTE_RACIAL.rawValue | BEF_FACE_ATTRIBUTE_ATTRACTIVE.rawValue
//        bef_effect_ai_face_attribute_detect_batch(<#T##handle: bef_effect_handle_t!##bef_effect_handle_t!#>, <#T##image: UnsafePointer<UInt8>!##UnsafePointer<UInt8>!#>, <#T##pixel_format: bef_ai_pixel_format##bef_ai_pixel_format#>, <#T##image_width: Int32##Int32#>, <#T##image_height: Int32##Int32#>, <#T##image_stride: Int32##Int32#>, <#T##ptr_base_info: UnsafePointer<bef_ai_face_106>!##UnsafePointer<bef_ai_face_106>!#>, <#T##face_count: Int32##Int32#>, <#T##config: UInt64##UInt64#>, <#T##ptr_face_attribute_result: UnsafeMutablePointer<bef_ai_face_attribute_result>!##UnsafeMutablePointer<bef_ai_face_attribute_result>!#>)
        // 多个人脸检测
        let result = bef_effect_ai_face_attribute_detect_batch(faceAttributeDetectHandle, buffer, format, width, height, bytesPerRow, faceInfo, faceCount, UInt64(attributeConfig), faceAttributeResult)
        if result != BEF_RESULT_SUC {
            NSLog("bef_effect_ai_face_attribute_detect_batch error: %d", result);
        }
    }
}
