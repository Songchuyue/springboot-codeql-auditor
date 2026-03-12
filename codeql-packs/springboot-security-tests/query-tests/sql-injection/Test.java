import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Test {
    private final JdbcTemplate jdbcTemplate = new JdbcTemplate();

    @GetMapping("/bad1")
    public void badConcat(@RequestParam String name) {
        String sql = "select * from users where name = '" + name + "'";
        jdbcTemplate.queryForList(sql);
    }

    @GetMapping("/bad2")
    public void badOrderBy(@RequestParam String sort) {
        String sql = "select * from users order by " + sort;
        jdbcTemplate.queryForList(sql);
    }

    @GetMapping("/bad3")
    public void badBuilder(@RequestParam String name) {
        StringBuilder sb = new StringBuilder("select * from users where name = '");
        sb.append(name);
        sb.append("'");
        jdbcTemplate.queryForList(sb.toString());
    }

    @GetMapping("/good1")
    public void goodPrepared(@RequestParam String name) {
        String sql = "select * from users where name = ?";
        jdbcTemplate.queryForList(sql, name);
    }

    @GetMapping("/good2")
    public void goodConstant() {
        String sql = "select * from users";
        jdbcTemplate.queryForList(sql);
    }

    @GetMapping("/bad4")
    public void badInterprocedural(@RequestParam String name) {
        executeQuery(name);
    }

    private void executeQuery(String name) {
        String sql = "select * from users where name = '" + name + "'";
        jdbcTemplate.queryForList(sql);
    }
}