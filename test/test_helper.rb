#require 'test/unit'
require 'minitest/autorun'
require 'unionpay'

UnionPay.environment  = :development    ## 测试环境， :pre_production  #预上线环境， 默认 # 线上环境
UnionPay.mer_id       = '800000000000000'
UnionPay.mer_abbr     = 'xxx'
UnionPay.security_key = 'xxx'
UnionPay.version      = '1.0.0'
UnionPay.charset      = 'UTF-8'
UnionPay.backend_url  = 'http://zhangfei.wusi.com/v1/union_pay_payments'
