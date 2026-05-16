package com.zhizhi.module.tag.controller;

import com.zhizhi.common.Result;
import com.zhizhi.common.SecurityUtil;
import com.zhizhi.module.tag.service.TagService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "标签管理")
@RestController
@RequestMapping("/tags")
@RequiredArgsConstructor
public class TagController {

    private final TagService tagService;

    @Operation(summary = "获取当前用户所有标签")
    @GetMapping
    public Result<List<com.zhizhi.module.tag.entity.Tag>> list() {
        return Result.success(tagService.getUserTags(SecurityUtil.getCurrentUserId()));
    }

    @Operation(summary = "删除标签")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        tagService.removeById(id);
        return Result.success();
    }
}
