package com.zhizhi.module.category.dto;

import lombok.Data;

import java.util.List;

@Data
public class CategoryVO {
    private Long id;
    private String name;
    private Long parentId;
    private Integer sort;
    private List<CategoryVO> children;
}
