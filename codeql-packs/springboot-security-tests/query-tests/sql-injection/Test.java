import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.RequestParam;

class Test {
    private final JdbcTemplate jdbcTemplate = null;
    private final NamedParameterJdbcTemplate namedParameterJdbcTemplate = null;
    private final Connection connection = null;
    private final EntityManager entityManager = null;

    private final UserService userService = new UserService();
    private final UserRepository userRepository = new UserRepository();
    private final DaoWrapper daoWrapper = new DaoWrapper();

    // =========================================================
    // 1. JdbcTemplate - bad
    // =========================================================

    void badJdbcConcat(@RequestParam String keyword) {
        String sql = "select * from users where name = '" + keyword + "'";
        jdbcTemplate.query(sql);
    }

    void badJdbcOrderBy(@RequestParam String keyword) {
        String sql = "select * from users order by " + keyword;
        jdbcTemplate.query(sql);
    }

    void badJdbcStringBuilder(@RequestParam String keyword) {
        StringBuilder sb = new StringBuilder("select * from users where name = '");
        sb.append(keyword);
        sb.append("'");
        jdbcTemplate.query(sb.toString());
    }

    void badJdbcFormat(@RequestParam String keyword) {
        String sql = String.format("select * from users where name = '%s'", keyword);
        jdbcTemplate.query(sql);
    }

    void badJdbcInterprocedural(@RequestParam String keyword) {
        String sql = buildUnsafeWhere(keyword);
        jdbcTemplate.query(sql);
    }

    // =========================================================
    // 2. JdbcTemplate / NamedParameterJdbcTemplate - good
    // =========================================================

    void goodJdbcPlaceholder(@RequestParam String keyword) {
        String sql = "select * from users where name = ?";
        jdbcTemplate.query(sql, keyword);
    }

    void goodNamedParameter(@RequestParam String keyword) {
        String sql = "select * from users where name = :name";
        MapSqlParameterSource params = new MapSqlParameterSource();
        params.addValue("name", keyword);
        namedParameterJdbcTemplate.query(sql, params);
    }

    void goodConstantSql() {
        String sql = "select * from users";
        jdbcTemplate.query(sql);
    }

    void goodWhitelistOrderBy(@RequestParam String keyword) {
        String orderBy = toWhitelistedOrderBy(keyword);
        String sql = "select * from users order by " + orderBy;
        jdbcTemplate.query(sql);
    }

    // =========================================================
    // 3. Plain JDBC - bad
    // =========================================================

    void badStatementExecuteQuery(@RequestParam String keyword) throws Exception {
        Statement st = connection.createStatement();
        String sql = "select * from users where name = '" + keyword + "'";
        st.executeQuery(sql);
    }

    void badStatementExecuteUpdate(@RequestParam String keyword) throws Exception {
        Statement st = connection.createStatement();
        String sql = "update users set role = 'admin' where name = '" + keyword + "'";
        st.executeUpdate(sql);
    }

    void badPreparedStatementWithDynamicSql(@RequestParam String keyword) throws Exception {
        String sql = "select * from users order by " + keyword;
        PreparedStatement ps = connection.prepareStatement(sql);
        ps.executeQuery();
    }

    // =========================================================
    // 4. Plain JDBC - good
    // =========================================================

    void goodPreparedStatementBind(@RequestParam String keyword) throws Exception {
        String sql = "select * from users where name = ?";
        PreparedStatement ps = connection.prepareStatement(sql);
        ps.setString(1, keyword);
        ps.executeQuery();
    }

    // =========================================================
    // 5. JPA / JPQL - bad
    // =========================================================

    void badCreateQueryConcat(@RequestParam String keyword) {
        String jpql = "from User u where u.name = '" + keyword + "'";
        entityManager.createQuery(jpql).getResultList();
    }

    void badCreateNativeQueryConcat(@RequestParam String keyword) {
        String sql = "select * from users where name = '" + keyword + "'";
        entityManager.createNativeQuery(sql).getResultList();
    }

    void badJpaOrderBy(@RequestParam String keyword) {
        String jpql = "from User u order by " + keyword;
        entityManager.createQuery(jpql).getResultList();
    }

    // =========================================================
    // 6. JPA / JPQL - good
    // =========================================================

    void goodCreateQuerySetParameter(@RequestParam String keyword) {
        Query q = entityManager.createQuery("from User u where u.name = :name");
        q.setParameter("name", keyword);
        q.getResultList();
    }

    void goodCreateNativeQuerySetParameter(@RequestParam String keyword) {
        Query q = entityManager.createNativeQuery("select * from users where name = ?");
        q.setParameter(1, keyword);
        q.getResultList();
    }

    void goodJpaWhitelistOrderBy(@RequestParam String keyword) {
        String orderBy = toWhitelistedOrderBy(keyword);
        entityManager.createQuery("from User u order by " + orderBy).getResultList();
    }

    // =========================================================
    // 7. Cross-layer / wrapper
    // =========================================================

    void badControllerToService(@RequestParam String keyword) {
        userService.findByName(keyword);
    }

    void badServiceToRepository(@RequestParam String keyword) {
        userService.findOrdered(keyword);
    }

    void badWrapperExecute(@RequestParam String keyword) {
        String sql = buildUnsafeWhere(keyword);
        daoWrapper.run(sql);
    }

    // =========================================================
    // 8. Helpers
    // =========================================================

    String buildUnsafeWhere(String keyword) {
        return "select * from users where name = '" + keyword + "'";
    }

    String buildUnsafeOrderBy(String keyword) {
        return "select * from users order by " + keyword;
    }

    String toWhitelistedOrderBy(String keyword) {
        if (keyword == null) {
            return "id";
        }

        switch (keyword) {
            case "id":
                return "id";
            case "name":
                return "name";
            case "createdAt":
                return "created_at";
            default:
                return "id";
        }
    }

    // =========================================================
    // nested helpers for cross-layer cases
    // =========================================================

    class UserService {
        void findByName(String keyword) {
            userRepository.rawFindByName(keyword);
        }

        void findOrdered(String keyword) {
            String sql = buildUnsafeOrderBy(keyword);
            userRepository.runSql(sql);
        }
    }

    class UserRepository {
        void rawFindByName(String keyword) {
            String sql = buildUnsafeWhere(keyword);
            jdbcTemplate.query(sql);
        }

        void runSql(String sql) {
            jdbcTemplate.query(sql);
        }
    }

    class DaoWrapper {
        void run(String sql) {
            jdbcTemplate.query(sql);
        }
    }
}