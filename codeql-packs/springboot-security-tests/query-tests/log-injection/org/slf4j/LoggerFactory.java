package org.slf4j;

public final class LoggerFactory {
    private LoggerFactory() {}

    private static final Logger NOP = new NopLogger();

    public static Logger getLogger(Class<?> clazz) {
        return NOP;
    }

    public static Logger getLogger(String name) {
        return NOP;
    }

    private static final class NopLogger implements Logger {
        public void trace(String msg) {}
        public void trace(String format, Object arg) {}
        public void trace(String format, Object... args) {}

        public void debug(String msg) {}
        public void debug(String format, Object arg) {}
        public void debug(String format, Object... args) {}

        public void info(String msg) {}
        public void info(String format, Object arg) {}
        public void info(String format, Object... args) {}

        public void warn(String msg) {}
        public void warn(String format, Object arg) {}
        public void warn(String format, Object... args) {}

        public void error(String msg) {}
        public void error(String format, Object arg) {}
        public void error(String format, Object... args) {}
    }
}