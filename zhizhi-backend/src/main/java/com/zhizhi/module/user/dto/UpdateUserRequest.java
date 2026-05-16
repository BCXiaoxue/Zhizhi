package com.zhizhi.module.user.dto;

import lombok.Data;

@Data
public class UpdateUserRequest {
    private String email;
    private String avatar;
    private String newPassword;
    private String oldPassword;
}
