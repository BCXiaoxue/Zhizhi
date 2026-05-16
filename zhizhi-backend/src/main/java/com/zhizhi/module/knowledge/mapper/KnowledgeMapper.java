package com.zhizhi.module.knowledge.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zhizhi.module.knowledge.dto.KnowledgeVO;
import com.zhizhi.module.knowledge.entity.Knowledge;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface KnowledgeMapper extends BaseMapper<Knowledge> {

    IPage<KnowledgeVO> selectPageVO(Page<KnowledgeVO> page,
                                    @Param("userId") Long userId,
                                    @Param("categoryId") Long categoryId,
                                    @Param("tagId") Long tagId);

    KnowledgeVO selectDetailVO(@Param("id") Long id);

    List<KnowledgeVO> searchByFullText(@Param("userId") Long userId,
                                       @Param("keyword") String keyword);
}
