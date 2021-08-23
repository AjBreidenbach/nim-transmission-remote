# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import os, httpclient
import asyncdispatch

import transmission_remote

const SAMPLE_URL = "http://releases.ubuntu.com/14.04.1/ubuntu-14.04.1-desktop-amd64.iso.torrent"
const SAMPLE_HASH = "cb84ccc10f296df72d6c40ba7a07c178a4323a14"

let temp = os.getTempDir()
let client = newHttpClient()


createDir(joinPath(temp, "transmission_remote_unittest"))
let torrentFileDest = joinPath(temp, "transmission_remote_unittest", "ubuntu.torrent")
if not fileExists(torrentFileDest):
  let torrentFileContents = client.getContent(SAMPLE_URL)
  writeFile(torrentFileDest, torrentFileContents)





suite "transmission remote tests":
  var tr: TransmissionRemote
  setup:
    tr = newTransmissionRemote()
    
  teardown:
    asyncCheck tr.removeTorrentsAndData()

  
  test "add from file":

    let response = waitFor tr.addTorrent(filename=torrentFileDest)

    check:
      response.hashString == SAMPLE_HASH
      response.isSuccessful


  test "add from url":
  
    let response = waitFor tr.addTorrent(SAMPLE_URL)

    check:
      response.hashString == SAMPLE_HASH
      response.isSuccessful
    
  test "error with a nonexistent file":
    
    let response = waitFor tr.addTorrent(SAMPLE_URL[0..10])
    check:
      response.isError


  test "get torrent":
  
    let response = waitFor tr.addTorrent(torrentFileDest)
    let id = response.id


    let torrent = waitFor tr.getTorrent(id, Key.id, Key.files, Key.eta)
    
    
  #test "rename torrent"

  test "set torrent (peer limit)":

    let response1 = waitFor tr.addTorrent(torrentFileDest)
    let id = response1.id


    var initialPeerLimit: int
    block:
      let response = waitFor tr.getTorrent(id, Key.peerLimit)
      initialPeerLimit = response.peerLimit
    
    let peerLimit = initialPeerLimit + 1
    let properties = newTorrentProperties()
    properties.peerLimit = peerLimit


    let response2 = waitFor tr.setTorrent(id, properties)
    #echo response2

    

    let response3 = waitFor tr.getTorrent(id, Key.peerLimit)
    
    check:
      response2.isSuccessful
      response3.peerLimit != initialPeerLimit


    
    
    
    #let response = waitFor

