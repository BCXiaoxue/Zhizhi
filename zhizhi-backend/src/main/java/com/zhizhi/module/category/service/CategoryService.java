package com.zhizhi.module.category.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.zhizhi.common.BusinessException;
import com.zhizhi.module.category.dto.CategoryVO;
import com.zhizhi.module.category.entity.Category;
import com.zhizhi.module.category.mapper.CategoryMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class CategoryService extends ServiceImpl<CategoryMapper, Category> {

    public List<CategoryVO> getTree(Long userId) {
        List<Category> all = list(new LambdaQueryWrapper<Category>()
                .eq(Category::getUserId, userId)
                .orderByAsc(Category::getSort));
        return buildTree(all, 0L);
    }

    private List<CategoryVO> buildTree(List<Category> all, Long parentId) {
        return all.stream()
                .filter(c -> c.getParentId().equals(parentId))
                .map(c -> {
                    CategoryVO vo = new CategoryVO();
                    vo.setId(c.getId());
                    vo.setName(c.getName());
                    vo.setParentId(c.getParentId());
                    vo.setSort(c.getSort());
                    vo.setChildren(buildTree(all, c.getId()));
                    return vo;
                })
                .collect(Collectors.toList());
    }

    public Category createCategory(Long userId, String name, Long parentId, Integer sort) {
        Category category = new Category();
        category.setUserId(userId);
        category.setName(name);
        category.setParentId(parentId == null ? 0L : parentId);
        category.setSort(sort == null ? 0 : sort);
        save(category);
        return category;
    }

    public void updateCategory(Long id, Long userId, String name, Integer sort) {
        Category category = getById(id);
        if (category == null || !category.getUserId().equals(userId)) throw BusinessException.forbidden();
        if (name != null) category.setName(name);
        if (sort != null) category.setSort(sort);
        updateById(category);
    }

    public void deleteCategory(Long id, Long userId) {
        Category category = getById(id);
        if (category == null || !category.getUserId().equals(userId)) throw BusinessException.forbidden();
        removeById(id);
    }
}
