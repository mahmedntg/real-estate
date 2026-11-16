package com.aqar.api.validation;

import jakarta.validation.groups.Default;

/**
 * Validation groups separating the constraints checked when a listing is created from those checked
 * when it is updated.
 *
 * <p>Both groups extend {@link Default} so the constraints declared without an explicit group are
 * still validated whenever one of these groups is requested.
 *
 * @author Mohamed Sayed
 */
public final class ValidationGroups {

    private ValidationGroups() {
    }

    /**
     * Constraints applied when a listing is created.
     *
     * @author Mohamed Sayed
     */
    public interface OnCreate extends Default {
    }

    /**
     * Constraints applied when a listing is updated.
     *
     * @author Mohamed Sayed
     */
    public interface OnUpdate extends Default {
    }
}
