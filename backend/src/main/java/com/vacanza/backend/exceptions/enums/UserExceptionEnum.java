package com.vacanza.backend.exceptions.enums;

import lombok.Getter;

@Getter
public enum UserExceptionEnum {

    USER_NOT_FOUND("User not found with given userId"),
    EMAIL_ALREADY_EXIST("User email is not verified");

    private final String explanation;

    UserExceptionEnum(String explanation) {
        this.explanation = explanation;
    }
}
