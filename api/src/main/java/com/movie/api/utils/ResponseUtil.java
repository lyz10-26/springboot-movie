package com.movie.api.utils;

import com.alibaba.fastjson.JSON;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

public final class ResponseUtil {

    private ResponseUtil() {
        // Utility class
    }

    public static void writeJson(HttpServletResponse response, Object o) {
        response.setHeader("Access-Control-Allow-Origin", "*");
        // Wildcard origins cannot be combined with credentialed CORS requests.
        response.setHeader("Access-Control-Allow-Methods", "POST, GET, PATCH, DELETE, PUT");
        response.setHeader("Access-Control-Max-Age", "3600");
        response.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
        response.setContentType("application/json;charset=utf-8");
        response.setStatus(HttpServletResponse.SC_OK);
        try {
            PrintWriter writer = response.getWriter();
            writer.write(JSON.toJSONString(o));
            writer.flush();
            // The servlet container owns the response writer lifecycle.
        } catch (IOException e) {
            throw new IllegalStateException("Failed to write JSON response", e);
        }
    }
}
