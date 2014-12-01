require 'test_helper'
require 'pp'
require 'cgi'

class UnionPay::ServiceTest < MiniTest::Test
  def generate_form
    param = {}
    param['transType']     = UnionPay::CONSUME                         #交易类型，CONSUME or PRE_AUTH
    param['orderAmount']   = 100                                           #交易金额
    param['orderNumber']   = '20131220151706000000'
    param['customerIp']    = '127.0.0.1'
    param['frontEndUrl']   = "http://www.example.com/sdk/utf8/front_notify.php"    #前台回调URL
    param['backEndUrl']    = "http://www.example.com/sdk/utf8/back_notify.php"     #后台回调URL
    param['orderTime']     = '20131220151706'
    param['orderCurrency'] = UnionPay::CURRENCY_CNY                    #交易币种，CURRENCY_CNY=>人民币
    UnionPay::Service.front_pay(param)
  end

  def generate_back_pay_service
    #交易类型 退货=REFUND 或 消费撤销=CONSUME_VOID, 如果原始交易是PRE_AUTH，那么后台接口也支持对应的
    #  PRE_AUTH_VOID(预授权撤销), PRE_AUTH_COMPLETE(预授权完成), PRE_AUTH_VOID_COMPLETE(预授权完成撤销)
    param = {}
    param['transType']             = UnionPay::REFUND
    param['origQid']               = '201110281442120195882'; #原交易返回的qid, 从数据库中获取
    param['orderAmount']           = 11000;        #交易金额
    param['orderNumber']           = '20131220151706000000'
    param['customerIp']            = '127.0.0.1';  #用户IP
    param['frontEndUrl']           = ""     #前台回调URL, 后台交易可为空
    param['backEndUrl']            = "http://www.example.com/sdk/utf8/back_notify.php"    #后台回调URL
    UnionPay::Service.back_pay(param)
  end

  def test_generate_form
    assert generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"} != nil
  end

  def test_front_pay_generate_form_with_different_environment
    UnionPay.environment = :development
    dev_form = generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"}
    UnionPay.environment = :pre_production
    pro_form = generate_form.form(target: '_blank', id: 'form'){"<input type='submit' />"}
    assert dev_form != pro_form
  end

  def test_back_pay_service
    dev_form = generate_back_pay_service
    assert dev_form.post != nil
  end

  def test_response
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
    param['transType'] = UnionPay::PRE_AUTH
    param['orderNumber'] = "01152521429447"
    param['orderTime'] = "20141125155316"
    query = UnionPay::Service.query(param)
    response = Rack::Utils.parse_nested_query(query.post.body)
    UnionPay::Service.response response
    #end
  end

end
