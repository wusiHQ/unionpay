#encoding:utf-8
require 'open-uri'
require 'digest'
require 'rack'
require 'net/http'
require 'active_support/core_ext/object/blank'

module UnionPay
  RESP_SUCCESS  = '00' #返回成功
  QUERY_SUCCESS = '0' #查询成功
  QUERY_FAIL    = '1'
  QUERY_WAIT    = '2'
  QUERY_INVALID = '3'
  class Service
    attr_accessor :args, :api_url

    def self.front_pay(param)
      new.instance_eval do
        param['orderTime']         ||= Time.now.strftime('%Y%m%d%H%M%S')         #交易时间, YYYYmmhhddHHMMSS
        param['orderCurrency']     ||= UnionPay::CURRENCY_CNY                    #交易币种，CURRENCY_CNY=>人民币
        param['transType']         ||= UnionPay::CONSUME
        trans_type = param['transType']
        if [UnionPay::CONSUME, UnionPay::PRE_AUTH].include? trans_type
          @api_url = UnionPay.front_pay_url
          self.args = PayParamsEmpty.merge(PayParams).merge(param)
          @param_check = UnionPay::PayParamsCheck
        else
          #Bad trans_type for front_pay. Use back_pay instead
          raise("Bad trans_type for front_pay. Use back_pay instead")
        end
        service
      end
    end

    def self.back_pay(param)
      new.instance_eval do
        param['orderTime']         ||= Time.now.strftime('%Y%m%d%H%M%S')         #交易时间, YYYYmmhhddHHMMSS
        param['orderCurrency']     ||= UnionPay::CURRENCY_CNY                    #交易币种，CURRENCY_CNY=>人民币
        param['transType']         ||= UnionPay::PRE_AUTH
        @api_url = UnionPay.back_pay_url
        self.args = PayParamsEmpty.merge(PayParams).merge(param)
        @param_check = UnionPay::PayParamsCheck
        trans_type = param['transType']
        service
      end
    end

    def self.response(param)
      new.instance_eval do
        if !param['signature'] || !param['signMethod']
          raise('No signature Or signMethod set in notify data!')
        end
        param.delete('signMethod')
        if param.delete('signature') != Service.sign(param)
          pp "********"
          pp Service.sign(param)
          pp "********"
          raise('Bad signature returned!')
        end
        self.args = param
        self
      end
    end

    def self.query(param)
      new.instance_eval do
        @api_url = UnionPay.query_url
        param['version'] = UnionPay::PayParams['version']
        param['charset'] = UnionPay::PayParams['charset']
        param['merId'] = UnionPay::PayParams['merId']

        self.args = param
        @param_check = UnionPay::QueryParamsCheck

        service
      end
    end

    def self.sign(param)
      sign_str = param.sort.map do |k,v|
        "#{k}=#{v}&" unless (UnionPay::SignIgnoreParams.include? k || v.blank?)
      end.join
      pp sign_str
      Digest::MD5.hexdigest(sign_str + Digest::MD5.hexdigest(UnionPay.security_key))
    end

    def form(options={})
      attrs = options.map { |k, v| "#{k}='#{v}'" }.join(' ')
      html = [
        "<form #{attrs} action='#{@api_url}' method='post'>"
      ]
      args.each do |k, v|
        html << "<input type='hidden' name='#{k}' value='#{v}' />"
      end
      if block_given?
        html << yield
        html << "</form>"
      end
      html.join
    end

    def post
      Net::HTTP.post_form URI(@api_url), self.args
    end

    def [](key)
      self.args[key]
    end

    private
    def service
      @param_check.each do |k|
        raise("KEY [#{k}] not set in params given") unless self.args.has_key? k
      end

      # signature
      self.args['signature']  = Service.sign(self.args)
      self.args['signMethod'] = UnionPay::SignMethod

      self
    end
  end
end
