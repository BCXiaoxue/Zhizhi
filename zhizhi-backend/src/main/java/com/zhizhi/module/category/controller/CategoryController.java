package com.zhizhi.module.category.controller;

import com.zhizhi.common.Result;
import com.zhizhi.common.SecurityUtil;
import com.zhizhi.module.category.dto.CategoryVO;
import com.zhizhi.module.category.entity.Category;
import com.zhizhi.module.category.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Tag(name = "分类管理")
@RestController
@RequestMapping("/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    @Operation(summary = "获取分类树")
    @GetMapping
    public Result<List<CategoryVO>> tree() {
        return Result.success(categoryService.getTree(SecurityUtil.getCurrentUserId()));
    }

    @Operation(summary = "新增分类")
    @PostMapping
    public Result<Category> create(@RequestBody Map<String, Object> body) {
        Long parentId = body.get("parentId") != null ? Long.parseLong(body.get("parentId").toString()) : null;
        Integer sort = body.get("sort") != null ? Integer.parseInt(body.get("sort").toString()) : null;
        return Result.success(categoryService.createCategory(
                SecurityUtil.getCurrentUserId(),
                body.get("name").toString(),
                parentId, sort));
    }

    @Operation(summary = "更新分类")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Integer sort = body.get("sort") != null ? Integer.parseInt(body.get("sort").toString()) : null;
        categoryService.updateCategory(id, SecurityUtil.getCurrentUserId(),
                body.get("name") != null ? body.get("name").toString() : null, sort);
        return Result.success();
    }

    @Operation(summary = "删除分类")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        categoryService.deleteCategory(id, SecurityUtil.getCurrentUserId());
        return Result.success();
    }
}
