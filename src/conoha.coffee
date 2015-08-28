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
#   hubot-authに依存しますのでHUBOT_AUTH_ADMINの設定も必要です。
#
# Author:
#   Yosuke Tamura <tamura.yosuke.tp8@gmail.com>
request = require 'request'
_       = require 'lodash'
#TODO: hubot-auth

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
        @expires = token.expires # ISO 8601
        @id      = token.id
        
      # アクセストークンがまだ有効か調べる
      isExpired: ->
        #TODO: 時刻比較(今は手動でトークン更新してる)
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

    class NotImplementedError extends Error
      
    #TODO: NotImplemented
    getAccountService: ->
      @accountService || @accountService = new AccountService(@access)

    class AccountService
      constructor: (@access) ->
        @endpoint = "https://account.tyo1.conoha.io"

      # https://www.conoha.jp/docs/account-get_version_list.html
      getVersions: (next) ->
        request.get
          url: @endpoint+'/'
          headers:
            'Accept': 'application/json'
          (err, res, body) ->
            if err
              console.log err
            else
              versions = JSON.parse(body).versions
              next(versions)

      # https://www.conoha.jp/docs/account-get_version_detail.html
      getVersionDetail: ->
        throw new NotImplemtntedError 'getVersionDetail'

      # https://www.conoha.jp/docs/account-order-item-list.html
      # https://www.conoha.jp/docs/account-order-item-detail-specified.html
      getOrderItems: (item_id) ->
        throw new NotImplemtntedError 'getOrderItems'

      # https://www.conoha.jp/docs/account-products.html
      getProductItems: ->
        throw new NotImplemtntedError 'getProductItems'

      # https://www.conoha.jp/docs/account-payment-histories.html
      getPaymentHistory: ->
        throw new NotImplemtntedError 'getPaymentHistory'

      # https://www.conoha.jp/docs/account-billing-invoices-list.html
      # https://www.conoha.jp/docs/account-order-item-detail-specified.html
      getBillingInvoices: (next, invoice_id) -> #TODO: options
        url = ""
        if invoice_id
          url = @endpoint+"/v1/#{authInfo.auth.tenantId}/billing-invoices/#{invoice_id}"
        else
          url = @endpoint+"/v1/#{authInfo.auth.tenantId}/billing-invoices"

        request.get
          url: url
          headers:
            'Accept': 'application/json'
            'X-Auth-Token': @access.token.id
          (err, res, body) ->
            if err
              console.log err
            else
              if invoice_id
                invoice = JSON.parse(body).billing_invoice
                next(invoice)
              else
                invoices = JSON.parse(body).billing_invoices
                next(invoices)
        #throw new NotImplementedError 'getBillingInvoices'

      # https://www.conoha.jp/docs/account-informations-list.html
      # https://www.conoha.jp/docs/account-informations-detail-specified.html
      getNotifications: (notification_code) ->
        throw new NotImplementedError 'getNotifications'

      # https://www.conoha.jp/docs/account-informations-marking.html
      putNotifications: (notification_code) ->
        throw new NotImplementedError 'putNotifications'

      # https://www.conoha.jp/docs/account-get_objectstorage_request_rrd.html
      getObjectStorageRRDRequest: ->
        throw new NotImplementedError 'getObjectStorageRRDRequest'

      # https://www.conoha.jp/docs/account-get_objectstorage_size_rrd.html
      getObjectStorageRRDSize: ->
        throw new NotImplementedError 'getObjectStorageRRDSize'

   

  # インスタンス生成
  conoha = new ConoHa(service, authInfo)

  # コマンド 
  robot.respond /conoha token/, (msg) ->
    if robot.auth.hasRole msg.envelope.user, 'conoha'
      conoha.authenticate()
      if conoha.access.token.id && conoha.access.token.expires
        msg.reply "トークン取得成功 #{conoha.access.token.id} #{conoha.access.token.expires}"
      else
        msg.reply "トークン取得失敗"

  robot.respond /conoha account version/, (msg) ->
    if robot.auth.hasRole msg.envelope.user, 'conoha'
      account = conoha.getAccountService()
      account.getVersions (versions) ->
        currentVersion = _.findWhere versions, {status: "CURRENT"}
        msg.reply "#{currentVersion.id}"

  robot.respond /conoha account billing invoice/, (msg) ->
    if robot.auth.hasRole msg.envelope.user, 'conoha'
      account = conoha.getAccountService()
      account.getBillingInvoices (invoices) ->
        if invoices.length != 0
          msg.reply "利用料金は#{invoices[0].bill_plas_tax}円です" 
          #NOTE: plusだと思うけどAPIがこうなんだからしょうがない
        else
          msg.reply "請求情報はありません"
