require 'test_helper'
require 'pp'
require 'cgi'

class UnionPay::ServiceTest < MiniTest::Test
  def generate_form
    param = {}
    param['transType']     = UnionPay::CONSUME                         #交易类型，CONSUME or PRE_AUTH
    param['orderAmount']   = 100                                           #交易金额
    param['orderNumber']   = '20131220151706000000123'
    param['customerIp']    = '127.0.0.1'
    param['frontEndUrl']   = "http://www.example.com/sdk/utf8/front_notify.php"    #前台回调URL
    param['orderTime']     = '20131220151706'
    param['orderCurrency'] = UnionPay::CURRENCY_CNY                    #交易币种，CURRENCY_CNY=>人民币
    UnionPay::Service.front_pay(param)
  end

  def generate_back_pay_service
    #交易类型 退货=REFUND 或 消费撤销=CONSUME_VOID, 如果原始交易是PRE_AUTH，那么后台接口也支持对应的
    #  PRE_AUTH_VOID(预授权撤销), PRE_AUTH_COMPLETE(预授权完成), PRE_AUTH_VOID_COMPLETE(预授权完成撤销)
    param = {}
    param['transType']             = UnionPay::PRE_AUTH
    param['orderAmount']           = 10;        #交易金额
    param['orderNumber']           = '1234567890abc'
    UnionPay::Service.backend_pay(param)
  end

  def est_generate_form
    assert generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"} != nil
  end

  def est_front_pay_generate_form_with_different_environment
    UnionPay.environment = :development
    dev_form = generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"}
    UnionPay.environment = :pre_production
    pro_form = generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"}
    assert dev_form != pro_form
  end

  def est_back_pay_service
    dev_form = generate_back_pay_service
    pp "======Test back pay service:======rake"
    result = dev_form.post().body
    pp result
    pp "======Test back pay service:======rake"
  end

  def est_response
    test = {
      'respCode' => '00',
      'tn'=>'201411251553160077762',
      'signMethod'=>'MD5',
      'transType'=>'02',
      'charset'=>'UTF-8',
      'signature'=>'e0a6dd598476378e3494c0ef5a38a7d2',
      'version'=>'1.0.0'
    }
    assert UnionPay::Service.response(test).args['respCode'] == UnionPay::RESP_SUCCESS
  end

  def test_query
    #assert_raise_message 'Bad signature returned!' do
    param = {}
    param['transType'] = UnionPay::PRE_AUTH_VOID
    param['orderNumber'] = '1112223334xmm'
    param['orderTime'] = "20141202101448"
    pp "======Test query======="
    query = UnionPay::Service.query(param)
    result = query.post.body
    pp result
    response = Rack::Utils.parse_nested_query(result)
    pp response
    pp "======Test query======="
    UnionPay::Service.response response
    #end
  end

  def est_cancel_preauth
    param = {}
    param['qn'] = "201412020445100613557"
    param['orderNumber'] = "1112223334xmm"
    param['orderAmount'] = 10

    cancel_preauth = UnionPay::Service.cancel_preauth(param)
    pp "======Test cancel preauth======="
    result = cancel_preauth.post.body
    pp result
    response = Rack::Utils.parse_nested_query(result)
    pp response
    pp "======Test cancel preauth======="
    UnionPay::Service.response response
  end

  def est_finish_preauth
    param = {}
    param['qn'] = "201412020445100613557"
    param['orderNumber'] = "1234567890abc123"
    param['orderAmount'] = 10
    cancel_preauth = UnionPay::Service.complete_preauth(param)
    pp "======Test finish preauth======"
    result = cancel_preauth.post.body
    pp result
    response = Rack::Utils.parse_nested_query(result)
    pp response
    pp "======Test finish preauth======"
    UnionPay::Service.response response
  end

  def est_cancel_complete_preauth
    param = {}
    param['qn'] = "201412020951220618837"
    param['orderNumber'] = "1112223334ssj"
    param['orderAmount'] = 10
    cancel_preauth = UnionPay::Service.cancel_complete_preauth(param)

    pp "======Test cancel complete preauth======="
    result = cancel_preauth.post().body
    pp result
    response = Rack::Utils.parse_nested_query(result)
    pp response
    pp "======Test cancel complete preauth======="
    UnionPay::Service.response response
  end
end
