package com.zhizhi.module.user.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.zhizhi.common.BusinessException;
import com.zhizhi.common.JwtUtil;
import com.zhizhi.module.user.dto.LoginRequest;
import com.zhizhi.module.user.dto.RegisterRequest;
import com.zhizhi.module.user.dto.UpdateUserRequest;
import com.zhizhi.module.user.entity.User;
import com.zhizhi.module.user.mapper.UserMapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class UserService extends ServiceImpl<UserMapper, User> {

    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final StringRedisTemplate redisTemplate;

    @Transactional
    public Map<String, Object> register(RegisterRequest req) {
        if (count(new LambdaQueryWrapper<User>().eq(User::getUsername, req.getUsername())) > 0) {
            throw new BusinessException(400, "用户名已存在");
        }
        User user = new User();
        user.setUsername(req.getUsername());
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        user.setEmail(req.getEmail());
        user.setRole(0);
        save(user);
        return buildLoginResult(user);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> login(LoginRequest req) {
        User user = getOne(new LambdaQueryWrapper<User>()
                .eq(User::getUsername, req.getUsername()));
        if (user == null || !passwordEncoder.matches(req.getPassword(), user.getPassword())) {
            throw new BusinessException(401, "用户名或密码错误");
        }
        return buildLoginResult(user);
    }

    @Transactional(readOnly = true)
    public void logout(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (StringUtils.hasText(header) && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            long remaining = jwtUtil.getExpiration(token) - System.currentTimeMillis();
            if (remaining > 0) {
                redisTemplate.opsForValue().set("blacklist:" + token, "1", remaining, TimeUnit.MILLISECONDS);
            }
        }
    }

    @Transactional(readOnly = true)
    public User getById(Long id) {
        User user = super.getById(id);
        if (user == null) throw BusinessException.notFound("用户");
        return user;
    }

    @Transactional
    public void updateUser(Long userId, UpdateUserRequest req) {
        User user = getById(userId);
        if (StringUtils.hasText(req.getNewPassword())) {
            if (!passwordEncoder.matches(req.getOldPassword(), user.getPassword())) {
                throw new BusinessException(400, "原密码错误");
            }
            user.setPassword(passwordEncoder.encode(req.getNewPassword()));
        }
        if (StringUtils.hasText(req.getEmail())) user.setEmail(req.getEmail());
        if (StringUtils.hasText(req.getAvatar())) user.setAvatar(req.getAvatar());
        updateById(user);
    }

    private Map<String, Object> buildLoginResult(User user) {
        String token = jwtUtil.generateToken(user.getId(), user.getUsername(), user.getRole());
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("userId", user.getId());
        result.put("username", user.getUsername());
        result.put("role", user.getRole());
        result.put("avatar", user.getAvatar());
        return result;
    }
}
