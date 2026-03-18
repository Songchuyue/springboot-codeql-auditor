package org.apache.commons.io.serialization;

import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;

public class ValidatingObjectInputStream extends ObjectInputStream {

    public ValidatingObjectInputStream(InputStream in) throws IOException {
        super(in);
    }

    public void accept(Class<?>... types) {
        // no-op test stub
    }

    public void accept(String... patterns) {
        // no-op test stub
    }
}