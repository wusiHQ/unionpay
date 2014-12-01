#require 'test/unit'
require 'minitest/autorun'
require 'unionpay'

UnionPay.environment  = :development    ## 测试环境， :pre_production  #预上线环境， 默认 # 线上环境
UnionPay.mer_id       = '880000000002205'
UnionPay.mer_abbr     = '上海无私科技'
UnionPay.security_key = '3ZCUBU7ZLyJB0dsbkixqi0x5JyhlHQs7'
UnionPay.version      = '1.0.0'
UnionPay.charset      = 'UTF-8'
UnionPay.backend_url  = 'http://zhangfei.wusi.com/v1/union_pay_payments'
