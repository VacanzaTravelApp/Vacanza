package com.vacanza.backend.exceptions;

import lombok.Getter;

@Getter
public enum UserLoginHistoryExceptionEnum {

    // NULL Info
    NullUserId("There is no user with this ID"),
    NullIP("IP address not found");

    private final String explanation;

    UserLoginHistoryExceptionEnum(String explanation) {
        this.explanation = explanation;
    }
}
