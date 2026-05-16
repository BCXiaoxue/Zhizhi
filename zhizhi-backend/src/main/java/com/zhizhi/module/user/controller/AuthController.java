package com.zhizhi.module.user.controller;

import com.zhizhi.common.Result;
import com.zhizhi.common.SecurityUtil;
import com.zhizhi.module.user.dto.LoginRequest;
import com.zhizhi.module.user.dto.RegisterRequest;
import com.zhizhi.module.user.dto.UpdateUserRequest;
import com.zhizhi.module.user.entity.User;
import com.zhizhi.module.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(name = "认证接口")
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @Operation(summary = "注册")
    @PostMapping("/register")
    public Result<Map<String, Object>> register(@Valid @RequestBody RegisterRequest req) {
        return Result.success(userService.register(req));
    }

    @Operation(summary = "登录")
    @PostMapping("/login")
    public Result<Map<String, Object>> login(@Valid @RequestBody LoginRequest req) {
        return Result.success(userService.login(req));
    }

    @Operation(summary = "注销")
    @PostMapping("/logout")
    public Result<Void> logout(HttpServletRequest request) {
        userService.logout(request);
        return Result.success();
    }

    @Operation(summary = "获取当前用户信息")
    @GetMapping("/me")
    public Result<User> me() {
        return Result.success(userService.getById(SecurityUtil.getCurrentUserId()));
    }

    @Operation(summary = "更新个人信息")
    @PutMapping("/me")
    public Result<Void> updateMe(@RequestBody UpdateUserRequest req) {
        userService.updateUser(SecurityUtil.getCurrentUserId(), req);
        return Result.success();
    }
}
