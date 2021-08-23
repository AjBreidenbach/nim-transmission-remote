import asyncdispatch, asyncfutures, httpclient, json, marshal, sequtils

type TransmissionRemote* = ref object
  url: string
  client: AsyncHttpClient
  sessionId: string
  removeLocalData: bool
  
type SetTorrentResponse = object
  result: string

type AddTorrentResponse* = object
  hashString*: string
  id*: int
  name*: string
  duplicate*: bool
  result: string


type TransmissionResponse = SetTorrentResponse | AddTorrentResponse

proc isSuccessful*(self: TransmissionResponse): bool =
  self.result == "success"

proc isError*(self: TransmissionResponse): bool =
  self.result != "success"

proc error*(self: TransmissionResponse): string =
  if self.result == "success": "" else: self.result

type TorrentAddOptions = distinct JsonNode

proc newTorrentAddOptions(): TorrentAddOptions = TorrentAddOptions newJObject()


template torrentAddOptionParameter(symbol: untyped, parameterType: untyped, rpcName: string = ""): untyped =
  proc `symbol=`*(self: TorrentAddOptions, symbol: parameterType) {.inject.}=
    when rpcName == "":
      let name = astToStr(symbol)
      JsonNode(self)[name] = % symbol
    else:
      JsonNode(self)[rpcName] = % symbol


torrentAddOptionParameter(cookies, string)
torrentAddOptionParameter(downloadDir, string, "download-dir")
torrentAddOptionParameter(filename, string)
torrentAddOptionParameter(url, string, "filename")
torrentAddOptionParameter(metainfo, string)
torrentAddOptionParameter(paused, bool)
torrentAddOptionParameter(peerLimit, int, "peer-limit")
torrentAddOptionParameter(bandwidthPriority, int)
torrentAddOptionParameter(filesWanted, openarray[int], "files-wanted")
torrentAddOptionParameter(filesUnwanted, openarray[int], "files-unwanted")
torrentAddOptionParameter(priorityHigh, openarray[int], "priority-high")
torrentAddOptionParameter(priorityLow, openarray[int], "priority-low")
torrentAddOptionParameter(priorityNormal, openarray[int], "priority-normal")


type FileInfo* = object
  bytesCompleted: int
  length: int
  name: string

type FileStats* = object
  bytesCompleted: int
  wanted: bool
  priority: int

type Peer* = object
  address: string
  clientName: string
  clientIsChoked: bool
  clientIsInterested: bool
  flagStr: string
  isDownloadingFrom: bool
  isEncrypted: bool
  isIncoming: bool
  isUploadingTo: bool
  isUTP: bool
  peerIsChoked: bool
  peerIsInterested: bool
  port: int
  progress: float
  rateToClient: int
  rateToPeer: int


type PeerStats* = object
  fromCache: int
  fromDht: int
  fromIncoming: int
  fromLpd: int
  fromLtep: int
  fromPex: int
  fromTracker: int


type Tracker* = object
  announce: string
  id: int
  scrape: string
  tier: int


type TrackerStats* = object
  announce: string
  announceState: int
  downloadCount: int
  hasAnnounced: bool
  hasScraped: bool
  host: string
  id: int
  isBackup: bool
  lastAnnouncePeerCount: int
  lastAnnounceResult: string
  lastAnnounceStartTime: int
  lastAnnounceSucceeded: bool
  lastAnnounceTime: int
  lastAnnounceTimeOut: bool
  lastScrapeResult: string
  lastScrapeStartTime: int
  lastScrapeTimeOut: bool
  leecherCount: int
  nextAnnounceTime: int
  nextScrapeTime: int
  scrape: string
  scraperState: int
  seederCount: int
  tier: int
  

type Key* {.pure.} = enum
  activityDate = "activityDate"
  addedDate = "addedDate"
  bandwidthPriority = "bandwidthPriority"
  comment = "comment"
  corruptEver = "corruptEver"
  creator = "creator"
  dateCreated = "dateCreated"
  desiredAvailable = "desiredAvailable"
  doneDate = "doneDate"
  downloadDir = "downloadDir"
  downloadedEver = "downloadedEver"
  downloadLimit = "downloadLimit"
  downloadLimited = "downloadLimited"
  editDate = "editDate"
  error = "error"
  errorString = "errorString"
  eta = "eta"
  etaIdle = "etaIdle"
  fileCount = "file-count"
  files = "files"
  fileStats = "fileStats"
  hashString = "hashString"
  haveUnchecked = "haveUnchecked"
  haveValid = "haveValid"
  honorsSessionLimits = "honorsSessionLimits"
  id = "id"
  isFinished = "isFinished"
  isStalled = "isStalled"
  isPrivate = "isPrivate"
  labels = "labels"
  leftUntilDone = "leftUntilDone"
  magnetLink = "magnetLink"
  manualAnnounceTime = "manualAnnounceTime"
  maxConnectedPeers = "maxConnectedPeers"
  metadataPercentComplete = "metadataPercentComplete"
  name = "name"
  peerLimit = "peer-limit"
  peers = "peers"
  peersConnected = "peersConnected"
  peersFrom = "peersFrom"
  peersGettingFromUs = "peersGettingFromUs"
  peersSendingToUs ="peersSendingToUs"
  percentDone = "percentDone"
  pieces = "pieces"
  pieceCount = "pieceCount"
  pieceSize = "pieceSize"
  priorities = "priorities"
  primaryMimeType = "primary-mime-type"
  queuePosition = "queuePosition"
  rateDownload = "rateDownload"
  rateUpload = "rateUpload"
  recheckProgress = "recheckProgress"
  secondsDownloading = "secondsDownloading"
  secondsSeeding = "secondsSeeding"
  seedIdleLimit = "seedIdleLimit"
  seedIdleMode = "seedIdleMode"
  seedRatioLimit = "seedRatioLimit"
  seedRatioMode = "seedRatioMode"
  sizeWhenDone = "sizeWhenDone"
  startDate = "startDate"
  status = "status"
  trackers = "trackers"
  trackerStats = "trackerStats"
  totalSize = "totalSize"
  torrentFile = "torrentFile"
  uploadedEver = "uploadedEver"
  uploadLimit = "uploadLimit"
  uploadLimited = "uploadLimited"
  uploadRatio = "uploadRatio"
  wanted = "wanted"
  webseeds = "webseeds"
  webseedsSendingToUs = "webseedsSendingToUs"

  filesWanted = "files-wanted"
  filesUnwanted = "files-unwanted"
  ids="ids"
  location="location"
  priorityHigh="priority-high"
  priorityLow="priority-low"
  priorityNormal="priority-normal"
  trackerAdd
  trackerRemove
  
  



type TorrentProperties* = object
  node: JsonNode

template torrentOptionProperty(symbol:untyped, parameterType:untyped, mutable=false): untyped =
  when mutable:
    proc `symbol=`*(t: TorrentProperties, value: parameterType) {.inject.} =
      t.node[$Key.symbol] = %value
  #[
  else:
    proc `symbol=`(t: TorrentProperties, value: parameterType) =
      t.node[$Key.symbol] = %value
  ]#


  proc `symbol`*(t: TorrentProperties): parameterType {.inject.} =
    t.node[$Key.symbol].to(parameterType)
    
proc newTorrentProperties*(): TorrentProperties = TorrentProperties(node: newJObject())

torrentOptionProperty(bandwidthPriority, int, mutable=true)
torrentOptionProperty(downloadLimit, int, mutable=true)
torrentOptionProperty(downloadLimited, bool, mutable=true)
torrentOptionProperty(filesWanted, seq[string], mutable=true)
torrentOptionProperty(filesUnwanted, seq[string], mutable=true)
torrentOptionProperty(honorsSessionLimits, bool, mutable=true)
torrentOptionProperty(ids, seq[int], mutable=true)
torrentOptionProperty(labels, seq[string], mutable=true)
torrentOptionProperty(location, string, mutable=true)
torrentOptionProperty(peerLimit, int, mutable=true)
torrentOptionProperty(priorityHigh, seq[int], mutable=true)
torrentOptionProperty(priorityLow, seq[int], mutable=true)
torrentOptionProperty(priorityNormal, seq[int], mutable=true)
torrentOptionProperty(queuePosition, int, mutable=true)
torrentOptionProperty(seedIdleLimit, int, mutable=true)
torrentOptionProperty(seedIdleMode, int, mutable=true)
torrentOptionProperty(seedRatioLimit, float, mutable=true)
torrentOptionProperty(seedRatioMode, int, mutable=true)
torrentOptionProperty(trackerAdd, seq[string], mutable=true)
torrentOptionProperty(trackerRemove, seq[int], mutable=true)
#torrentOptionProperty(trackerReplace, seq[int], mutable=true)
#TODO what is the parameterType on this
torrentOptionProperty(uploadLimit, int, mutable=true)
torrentOptionProperty(uploadLimited, bool, mutable=true)

torrentOptionProperty(activityDate, int)
torrentOptionProperty(addedDate, int)
torrentOptionProperty(comment, string)
torrentOptionProperty(corruptEver, int)
torrentOptionProperty(creator, string)
torrentOptionProperty(dateCreated, int)
torrentOptionProperty(desiredAvailable, int)
torrentOptionProperty(doneDate, int)
torrentOptionProperty(downloadDir, string)
torrentOptionProperty(downloadedEver, int)
torrentOptionProperty(editDate, int)
torrentOptionProperty(error, int)
torrentOptionProperty(errorString, string)
torrentOptionProperty(eta, int)
torrentOptionProperty(etaIdle, int)
torrentOptionProperty(fileCount, int)
torrentOptionProperty(files, seq[FileInfo])
torrentOptionProperty(fileStats, seq[FileStats])
torrentOptionProperty(hashString, string)
torrentOptionProperty(haveUnchecked, int)
torrentOptionProperty(haveValid, int)
torrentOptionProperty(honorsSessionLimits, bool)
torrentOptionProperty(id, int)
torrentOptionProperty(isFinished, bool)
torrentOptionProperty(isPrivate, bool)
torrentOptionProperty(isStalled, bool)
#torrentOptionProperty(labels, seq[string])
torrentOptionProperty(leftUntilDone, int)
torrentOptionProperty(magnetLink, string)
torrentOptionProperty(manualAnnounceTime, int)
torrentOptionProperty(maxConnectedPeers, int)
torrentOptionProperty(metadataPercentComplete, float)
torrentOptionProperty(name, string)
torrentOptionProperty(peers, seq[Peer])
torrentOptionProperty(peersConnected, int)
torrentOptionProperty(peersFrom, seq[PeerStats])
torrentOptionProperty(peersGettingFromUs, int)
torrentOptionProperty(peersSendingToUs, int)
torrentOptionProperty(percentDone, float)
torrentOptionProperty(pieces, string)
torrentOptionProperty(pieceCount, int)
torrentOptionProperty(pieceSize, int)
#priorities
torrentOptionProperty(primaryMimeType, string)
torrentOptionProperty(queuePosition, int)
torrentOptionProperty(rateDownload, int)
torrentOptionProperty(rateUpload, int)
torrentOptionProperty(recheckProgress, float)
torrentOptionProperty(secondsDownloading, int)
torrentOptionProperty(secondsSeeding, int)
torrentOptionProperty(startDate, int)
torrentOptionProperty(status, int)
torrentOptionProperty(trackers, seq[Tracker])
torrentOptionProperty(trackerStats, seq[TrackerStats])
torrentOptionProperty(totalSize, int)
torrentOptionProperty(torrentFile, string)
torrentOptionProperty(uploadedEver, int)
torrentOptionProperty(uploadRatio, float)
#wanted
torrentOptionProperty(webseeds, seq[string])
torrentOptionProperty(webseedsSendingToUs, int)




proc newTransmissionRemote*(host="localhost", path="/transmission/rpc", port=9091, ssl=false, removeLocalData=false): TransmissionRemote =
  TransmissionRemote(
    url: "http://" & host & ':' & $port & path,
    client: newAsyncHttpClient(),
    sessionId: "",
    removeLocalData: removeLocalData
  )



proc postJSON(tr: TransmissionRemote, payload: JsonNode): Future[AsyncResponse] {.async.} =
  let headers = newHttpHeaders({"Content-Type": "application/json", "X-Transmission-Session-Id": tr.sessionId})
  result = await tr.client.request(tr.url, HttpPost, $payload, headers)
  tr.sessionId = result.headers.getOrDefault("X-Transmission-Session-Id", HttpHeaderValues(@[tr.sessionId]))
  if result.status == Http409:
    result = await postJSON(tr, payload)

  #echo payload
  #echo await result.body
  return result
  
  
proc postAdd(tr: TransmissionRemote, data: JsonNode): Future[AddTorrentResponse] {.async.} =
  let response = await tr.postJSON(data)
  let body = parseJson(await response.body)
  let arguments = body["arguments"]

  var marshalledResponse = newJObject()
  try:
    marshalledResponse = arguments["torrent-added"]
  except: discard
  try:
    marshalledResponse = arguments["torrent-duplicate"]

    marshalledResponse["duplicate"] = %true
  except: discard

  marshalledResponse["result"] = body["result"]

  result = to[AddTorrentResponse] $marshalledResponse


proc addTorrent*(tr: TransmissionRemote, options: TorrentAddOptions): Future[AddTorrentResponse] =
  let serialized = %* {
    "arguments": JsonNode(options),
    "method": %"torrent-add"
  }

  tr.postAdd(serialized)


proc addTorrent*(tr: TransmissionRemote,
filename="", download_dir="" ,metainfo="",paused=false
): Future[AddTorrentResponse] =
  var torrentOptions = newTorrentAddOptions()
  if download_dir.len != 0: torrentOptions.downloadDir=download_dir
  if filename.len != 0: torrentOptions.filename=filename
  if metainfo.len != 0: torrentOptions.metainfo=metainfo
  if paused: torrentOptions.paused=paused

  tr.addTorrent(torrentOptions)
  

proc getTorrentsInner(tr: TransmissionRemote,
                 ids: seq[int]= @[], requestedProperties: seq[Key] = @[Key.id]): Future[seq[TorrentProperties]] {.async.}=


  let payload = %*{
    "method": "torrent-get",
    "arguments": {
      "fields": %requestedProperties.mapIt($it)
    }
  }

  if ids.len > 0:
    payload["arguments"]["ids"] = %ids

  let response = await tr.postJSON(payload)


  let arguments = parseJson(await response.body)["arguments"]
  result = arguments["torrents"].getElems().mapIt(TorrentProperties(node: it))

proc getTorrents*(tr: TransmissionRemote, ids: openarray[int], requestedProperties: varargs[Key]): Future[seq[TorrentProperties]] =
  return tr.getTorrentsInner(@ids, @requestedProperties)

proc getAllTorrents*(tr: TransmissionRemote, requestedProperties: varargs[Key]): Future[seq[TorrentProperties]] =
  return tr.getTorrentsInner(@[], @requestedProperties)

proc getTorrentInner(tr: TransmissionRemote, id: int, requestedProperties: seq[Key] = @[Key.id]): Future[TorrentProperties] {.async.} =
  result = (await tr.getTorrentsInner(@[id], requestedProperties))[0]

proc getTorrent*(tr: TransmissionRemote, id: int, requestedProperties: varargs[Key]): Future[TorrentProperties] =
  return tr.getTorrentInner(id, @requestedProperties)


proc setTorrentsInner(tr: TransmissionRemote, properties: TorrentProperties): Future[SetTorrentResponse] {.async.} =
  let payload = %*{
    "method": "torrent-set",
    "arguments": properties.node
  }
  
  let response = await tr.postJSON(payload)
  let jsonResponse = parseJson(await response.body)

  return SetTorrentResponse(result: jsonResponse["result"].getStr())


proc setTorrents*(tr:TransmissionRemote, torrents: openarray[int] = @[], properties: TorrentProperties): Future[SetTorrentResponse] =
  properties.ids = @torrents
  tr.setTorrentsInner(properties)
  
proc setTorrent*(tr: TransmissionRemote, torrentId: int, properties: TorrentProperties): Future[SetTorrentResponse] =
  properties.ids = @[torrentId]
  tr.setTorrentsInner(properties)

proc voidResponse(f: Future[AsyncResponse]): Future[void] {.async.} =
  let response = await f

proc removeTorrents*(tr: TransmissionRemote, ids: varargs[int] = []): Future[void] =
  let payload = %*{
    "method": "torrent-remove",
    "arguments": {
      "delete-local-data": %tr.removeLocalData
    }
  }

  if ids.len > 0:
    payload["arguments"]["ids"] = %ids

  return voidResponse(tr.postJSON(payload))


proc removeTorrentsAndData*(tr: TransmissionRemote, ids: varargs[int] = []): Future[void] =
  let payload = %*{
    "method": "torrent-remove",
    "arguments": {
      "delete-local-data": %true
    }
  }

  if ids.len > 0:
    payload["arguments"]["ids"] = %ids

  return voidResponse(tr.postJSON(payload))

proc removeTorrent*(tr: TransmissionRemote, id: int, deleteLocalData = false): Future[void] =
  if deleteLocalData: tr.removeTorrentsAndData(id)
  else: tr.removeTorrents(id)

proc removeTorrentAndData*(tr: TransmissionRemote, id: int): Future[void] =
  tr.removeTorrentsAndData(id)

  
when isMainModule:
  discard
