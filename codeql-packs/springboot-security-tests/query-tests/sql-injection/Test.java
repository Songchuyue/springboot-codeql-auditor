import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
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

    @GetMapping("/badJdbcConcat")
    void badJdbcConcat(@RequestParam String keyword) {
        String sql = "select * from users where name = '" + keyword + "'";
        jdbcTemplate.query(sql);
    }

    @GetMapping("/badJdbcOrderBy")
    void badJdbcOrderBy(@RequestParam String keyword) {
        String sql = "select * from users order by " + keyword;
        jdbcTemplate.query(sql);
    }

    @GetMapping("/badJdbcStringBuilder")
    void badJdbcStringBuilder(@RequestParam String keyword) {
        StringBuilder sb = new StringBuilder("select * from users where name = '");
        sb.append(keyword);
        sb.append("'");
        jdbcTemplate.query(sb.toString());
    }

    @GetMapping("/badJdbcFormat")
    void badJdbcFormat(@RequestParam String keyword) {
        String sql = String.format("select * from users where name = '%s'", keyword);
        jdbcTemplate.query(sql);
    }

    @GetMapping("/badJdbcInterprocedural")
    void badJdbcInterprocedural(@RequestParam String keyword) {
        String sql = buildUnsafeWhere(keyword);
        jdbcTemplate.query(sql);
    }

    // =========================================================
    // 2. JdbcTemplate / NamedParameterJdbcTemplate - good
    // =========================================================

    @GetMapping("/goodJdbcPlaceholder")
    void goodJdbcPlaceholder(@RequestParam String keyword) {
        String sql = "select * from users where name = ?";
        jdbcTemplate.query(sql, keyword);
    }

    @GetMapping("/goodNamedParameter")
    void goodNamedParameter(@RequestParam String keyword) {
        String sql = "select * from users where name = :name";
        MapSqlParameterSource params = new MapSqlParameterSource();
        params.addValue("name", keyword);
        namedParameterJdbcTemplate.query(sql, params);
    }

    @GetMapping("/goodConstantSql")
    void goodConstantSql() {
        String sql = "select * from users";
        jdbcTemplate.query(sql);
    }

    @GetMapping("/goodWhitelistOrderBy")
    void goodWhitelistOrderBy(@RequestParam String keyword) {
        String orderBy = toWhitelistedOrderBy(keyword);
        String sql = "select * from users order by " + orderBy;
        jdbcTemplate.query(sql);
    }

    // =========================================================
    // 3. Plain JDBC - bad
    // =========================================================

    @GetMapping("/badStatementExecuteQuery")
    void badStatementExecuteQuery(@RequestParam String keyword) throws Exception {
        Statement st = connection.createStatement();
        String sql = "select * from users where name = '" + keyword + "'";
        st.executeQuery(sql);
    }

    @GetMapping("/badStatementExecuteUpdate")
    void badStatementExecuteUpdate(@RequestParam String keyword) throws Exception {
        Statement st = connection.createStatement();
        String sql = "update users set role = 'admin' where name = '" + keyword + "'";
        st.executeUpdate(sql);
    }

    @GetMapping("/badPreparedStatementWithDynamicSql")
    void badPreparedStatementWithDynamicSql(@RequestParam String keyword) throws Exception {
        String sql = "select * from users order by " + keyword;
        PreparedStatement ps = connection.prepareStatement(sql);
        ps.executeQuery();
    }

    // =========================================================
    // 4. Plain JDBC - good
    // =========================================================

    @GetMapping("/goodPreparedStatementBind")
    void goodPreparedStatementBind(@RequestParam String keyword) throws Exception {
        String sql = "select * from users where name = ?";
        PreparedStatement ps = connection.prepareStatement(sql);
        ps.setString(1, keyword);
        ps.executeQuery();
    }

    // =========================================================
    // 5. JPA / JPQL - bad
    // =========================================================

    @GetMapping("/badCreateQueryConcat")
    void badCreateQueryConcat(@RequestParam String keyword) {
        String jpql = "from User u where u.name = '" + keyword + "'";
        entityManager.createQuery(jpql).getResultList();
    }

    @GetMapping("/badCreateNativeQueryConcat")
    void badCreateNativeQueryConcat(@RequestParam String keyword) {
        String sql = "select * from users where name = '" + keyword + "'";
        entityManager.createNativeQuery(sql).getResultList();
    }

    @GetMapping("/badJpaOrderBy")
    void badJpaOrderBy(@RequestParam String keyword) {
        String jpql = "from User u order by " + keyword;
        entityManager.createQuery(jpql).getResultList();
    }

    // =========================================================
    // 6. JPA / JPQL - good
    // =========================================================

    @GetMapping("/goodCreateQuerySetParameter")
    void goodCreateQuerySetParameter(@RequestParam String keyword) {
        Query q = entityManager.createQuery("from User u where u.name = :name");
        q.setParameter("name", keyword);
        q.getResultList();
    }

    @GetMapping("/goodCreateNativeQuerySetParameter")
    void goodCreateNativeQuerySetParameter(@RequestParam String keyword) {
        Query q = entityManager.createNativeQuery("select * from users where name = ?");
        q.setParameter(1, keyword);
        q.getResultList();
    }

    @GetMapping("/goodJpaWhitelistOrderBy")
    void goodJpaWhitelistOrderBy(@RequestParam String keyword) {
        String orderBy = toWhitelistedOrderBy(keyword);
        entityManager.createQuery("from User u order by " + orderBy).getResultList();
    }

    // =========================================================
    // 7. Cross-layer / wrapper
    // =========================================================

    @GetMapping("/badControllerToService")
    void badControllerToService(@RequestParam String keyword) {
        userService.findByName(keyword);
    }

    @GetMapping("/badServiceToRepository")
    void badServiceToRepository(@RequestParam String keyword) {
        userService.findOrdered(keyword);
    }

    @GetMapping("/badWrapperExecute")
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