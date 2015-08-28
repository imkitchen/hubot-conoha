# Description
#   ConoHa APIを叩く
#
# Configuration:
#   HUBOT_CONOHA_IDENTITY_SERVICE
#   HUBOT_CONOHA_TENANT_ID
#   HUBOT_CONOHA_USERNAME
#   HUBOT_CONOHA_PASSWORD
#
# Commands:
#   hubot conoha billing invoices - 課金アイテムへの請求データ一覧を取得します。
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Yosuke Tamura <tamura.yosuke.tp8@gmail.com>
request = require 'request'

module.exports = (robot) ->

  # 認証情報
  service  = process.env.HUBOT_CONOHA_IDENTITY_SERVICE
  authInfo =
    auth:
      passwordCredentials:
        username: process.env.HUBOT_CONOHA_USERNAME
        password: process.env.HUBOT_CONOHA_PASSWORD
      tenantId: process.env.HUBOT_CONOHA_TENANT_ID

  #TODO: 別モジュールに切り分けたさ
  # ConoHa APIクラス
  class ConoHa
    constructor: (@service, @authInfo) ->
      @access = @getAccess()
      @token  = new Token(@access.token)

    # トークンクラス
    class Token
      constructor: (token) ->
        @expires = token.expires
        @id      = token.id
        
      # アクセストークンがまだ有効か調べる
      isExpired: ->
        #TODO: 時刻比較
        true || false

    # アクセス情報を取得する
    getAccess: ->
      self = @
      request.post
        url: @service+'/tokens'
        headers: 
          'Accept': 'application/json'
        form: JSON.stringify @authInfo
        (err, res, body) ->
          if err
            #robot.logger.log err
            console.log err
          else
            JSON.parse(body).access

    #TODO: NotImplemented
    account:
      orderItems: (item_id) ->
        {}
      productItems: ->
        {}
      paymentHistory: ->
        {}
      billingInvoices: (invoice_id) ->
        #if invoice_id
        # 
        #else
        {}
      

  # インスタンス生成
  conoha = new ConoHa(service, authInfo)
  
  robot.respond /token/, (msg) ->
    access = conoha.getAccess()
    if access.token
      msg.reply = "トークン取得成功"
    else
      msg.reply = "トークン取得失敗"

  robot.respond /billing invoices/, (msg) ->
    #
    msg.reply ""
