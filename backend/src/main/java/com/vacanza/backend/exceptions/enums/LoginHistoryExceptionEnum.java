package com.vacanza.backend.exceptions.enums;

import lombok.Getter;

@Getter
public enum LoginHistoryExceptionEnum {

    //NULL Info
    NullUserId("There is no user with this ID"),
    NullIP("IP address not found");

    private final String explanation;

    LoginHistoryExceptionEnum (String explanation) {
        this.explanation = explanation;
    }
}
