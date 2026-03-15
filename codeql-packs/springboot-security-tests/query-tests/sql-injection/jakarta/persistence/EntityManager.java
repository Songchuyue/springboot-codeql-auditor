package jakarta.persistence;

public interface EntityManager {
    Query createQuery(String qlString);
    Query createNativeQuery(String sqlString);
}