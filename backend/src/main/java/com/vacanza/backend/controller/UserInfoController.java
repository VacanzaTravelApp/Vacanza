package com.vacanza.backend.controller;


import com.vacanza.backend.service.UserInfoService;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "/userInfo")
@AllArgsConstructor
public class UserInfoController {

    private final UserInfoService userInfoService;
    
}
