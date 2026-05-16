package com.zhizhi.module.tag.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.zhizhi.module.tag.entity.Tag;
import com.zhizhi.module.tag.mapper.TagMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class TagService extends ServiceImpl<TagMapper, Tag> {

    public List<Tag> getUserTags(Long userId) {
        return list(new LambdaQueryWrapper<Tag>().eq(Tag::getUserId, userId));
    }

    public List<Long> getOrCreateTagIds(Long userId, List<String> tagNames) {
        if (tagNames == null || tagNames.isEmpty()) return List.of();

        // 一次查出所有已存在的 tags，避免 N 次查询
        Map<String, Long> existing = list(new LambdaQueryWrapper<Tag>()
                .eq(Tag::getUserId, userId)
                .in(Tag::getName, tagNames))
            .stream()
            .collect(Collectors.toMap(Tag::getName, Tag::getId));

        List<Tag> toCreate = tagNames.stream()
            .filter(name -> !existing.containsKey(name))
            .map(name -> { Tag t = new Tag(); t.setUserId(userId); t.setName(name); return t; })
            .collect(Collectors.toList());

        if (!toCreate.isEmpty()) {
            saveBatch(toCreate);
            toCreate.forEach(t -> existing.put(t.getName(), t.getId()));
        }

        return tagNames.stream()
            .map(existing::get)
            .filter(Objects::nonNull)
            .collect(Collectors.toList());
    }
}
