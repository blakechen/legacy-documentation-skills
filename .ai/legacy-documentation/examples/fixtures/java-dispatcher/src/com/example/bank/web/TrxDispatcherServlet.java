package com.example.bank.web;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.example.bank.util.TrxFactory;
import com.example.bank.trx.StdTrxObject;

/** Front controller. Routes on the TRXCODE request parameter. */
public class TrxDispatcherServlet extends HttpServlet {

    public void doPost(HttpServletRequest req, HttpServletResponse res) {
        String code = req.getParameter("TRXCODE");
        if (code == null || code.length() == 0) {
            res.setStatus(400);
            return;
        }
        StdTrxObject trx = TrxFactory.create(code);
        if (trx == null) {
            res.setStatus(404);
            return;
        }
        trx.execute(req, res);
    }
}
