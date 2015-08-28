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
#   hubot conoha token - アクセストークンの更新
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
      @authenticate()

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
    authenticate: ->
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
            self.access = JSON.parse(body).access

    #TODO: NotImplemented
    account:
      orderItems: (item_id) ->
        {}
      productItems: ->
        {}
      paymentHistory: ->
        {}
      billingInvoices: (invoice_id) ->
        {}


      
  # インスタンス生成
  conoha = new ConoHa(service, authInfo)

  # コマンド 
  robot.respond /conoha token/, (msg) ->
    conoha.authenticate()
    if conoha.access.token.id && conoha.access.token.expires
      msg.reply "トークン取得成功 #{conoha.access.token.id} #{conoha.access.token.expires}"
    else
      msg.reply "トークン取得失敗"

  robot.respond /conoha billing invoices/, (msg) ->
    #
    msg.reply ""
