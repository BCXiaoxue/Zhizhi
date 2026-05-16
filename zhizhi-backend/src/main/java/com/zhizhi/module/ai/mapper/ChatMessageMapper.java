package com.zhizhi.module.ai.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhizhi.module.ai.entity.ChatMessage;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ChatMessageMapper extends BaseMapper<ChatMessage> {
}
