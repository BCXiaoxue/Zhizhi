package com.zhizhi.common;

import lombok.Getter;

@Getter
public class BusinessException extends RuntimeException {
    private final int code;

    public BusinessException(String message) {
        super(message);
        this.code = 500;
    }

    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }

    public static BusinessException notFound(String resource) {
        return new BusinessException(404, resource + "不存在");
    }

    public static BusinessException forbidden() {
        return new BusinessException(403, "无权限操作");
    }
}
