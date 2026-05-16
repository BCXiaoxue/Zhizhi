package com.zhizhi.module.user.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zhizhi.common.PageResult;
import com.zhizhi.common.Result;
import com.zhizhi.module.user.entity.User;
import com.zhizhi.module.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "管理员-用户管理")
@RestController
@RequestMapping("/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final UserService userService;

    @Operation(summary = "分页查询用户列表")
    @GetMapping
    public Result<PageResult<User>> list(
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "10") long size) {
        Page<User> page = userService.page(new Page<>(current, size));
        return Result.success(PageResult.of(page));
    }

    @Operation(summary = "删除用户")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        userService.removeById(id);
        return Result.success();
    }
}
