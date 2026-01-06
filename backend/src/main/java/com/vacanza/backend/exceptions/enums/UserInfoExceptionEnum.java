package com.vacanza.backend.exceptions.enums;

import lombok.Getter;

@Getter
public enum UserInfoExceptionEnum {
    USER_NOT_FOUND("User not found with given userId"),
    PROFILE_NOT_FOUND("Profile info not found for this user. Please create one.");


    private final String explanation;

    UserInfoExceptionEnum(String explanation) {
        this.explanation = explanation;
    }
}
