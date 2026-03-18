import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.Serializable;
import java.util.Base64;

import org.apache.commons.io.serialization.ValidatingObjectInputStream;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
class Test {

    private final DeserializeService deserializeService = new DeserializeService();

    // =========================================================
    // 1. Direct bad cases
    // =========================================================

    @GetMapping("/badDirectReadObject")
    Object badDirectReadObject(@RequestParam String payload) throws Exception {
        byte[] bytes = Base64.getDecoder().decode(payload);
        ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(bytes));
        return ois.readObject();
    }

    @GetMapping("/badBufferedReadObject")
    Object badBufferedReadObject(@RequestParam String payload) throws Exception {
        byte[] bytes = decode(payload);
        InputStream raw = new ByteArrayInputStream(bytes);
        ObjectInputStream ois = new ObjectInputStream(new BufferedInputStream(raw));
        return ois.readObject();
    }

    // =========================================================
    // 2. Interprocedural / helper cases
    // =========================================================

    @GetMapping("/badHelperFactory")
    Object badHelperFactory(@RequestParam String payload) throws Exception {
        ObjectInputStream ois = openUnsafeStream(payload);
        return ois.readObject();
    }

    @GetMapping("/badControllerToService")
    Object badControllerToService(@RequestParam String payload) throws Exception {
        return deserializeService.deserialize(payload);
    }

    // =========================================================
    // 3. Good cases
    // =========================================================

    /**
     * 官方库已把 ValidatingObjectInputStream 视为安全类型。
     */
    @GetMapping("/goodValidatingObjectInputStream")
    Object goodValidatingObjectInputStream(@RequestParam String payload) throws Exception {
        byte[] bytes = decode(payload);
        ValidatingObjectInputStream vois = new ValidatingObjectInputStream(new ByteArrayInputStream(bytes));
        vois.accept(User.class);
        return vois.readObject();
    }

    /**
     * 只读基本类型，不触发对象反序列化。
     */
    @GetMapping("/goodPrimitiveOnly")
    int goodPrimitiveOnly(@RequestParam String payload) throws Exception {
        byte[] bytes = decode(payload);
        DataInputStream in = new DataInputStream(new ByteArrayInputStream(bytes));
        return in.readInt();
    }

    /**
     * 常量输入，不应被当成用户可控 source。
     */
    @GetMapping("/goodConstantBytes")
    Object goodConstantBytes() throws Exception {
        byte[] bytes = new byte[] { 1, 2, 3, 4 };
        ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(bytes));
        return ois.readObject();
    }

    // =========================================================
    // Helpers
    // =========================================================

    byte[] decode(String payload) {
        return Base64.getDecoder().decode(payload);
    }

    ObjectInputStream openUnsafeStream(String payload) throws Exception {
        byte[] bytes = decode(payload);
        return new ObjectInputStream(new ByteArrayInputStream(bytes));
    }

    static class DeserializeService {
        Object deserialize(String payload) throws Exception {
            byte[] bytes = Base64.getDecoder().decode(payload);
            return new DeserializeRepository().read(bytes);
        }
    }

    static class DeserializeRepository {
        Object read(byte[] bytes) throws Exception {
            ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(bytes));
            return ois.readObject();
        }
    }

    static class User implements Serializable {
        private static final long serialVersionUID = 1L;

        String name;

        User() {
        }

        User(String name) {
            this.name = name;
        }
    }
}