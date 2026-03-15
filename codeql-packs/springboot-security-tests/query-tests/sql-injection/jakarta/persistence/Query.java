package jakarta.persistence;

import java.util.List;

public interface Query {
    Query setParameter(String name, Object value);
    Query setParameter(int position, Object value);
    @SuppressWarnings("rawtypes")
    List getResultList();
}