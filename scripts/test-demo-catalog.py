#!/usr/bin/env python3
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest

def module(name, path):
    spec=importlib.util.spec_from_file_location(name,path); m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m

g=module('generator',Path(__file__).with_name('generate-demo-catalog.py'))
p=module('publisher',Path(__file__).with_name('publish-demo-catalog.py'))

class ArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup);self.root=Path(self.temp.name)
        self.tag='v1.2.3';self.archive=self.root/'engrt-v1.2.3-linux-amd64.tar.gz';self.sums=self.root/'SHA256SUMS.txt'
    def write(self, bad=None, duplicate=False):
        with tarfile.open(self.archive,'w:gz') as t:
            entry=tarfile.TarInfo('engrt-v1.2.3-linux-amd64/engrt');entry.size=2;t.addfile(entry,io.BytesIO(b'ok'))
            if duplicate:t.addfile(entry,io.BytesIO(b'ok'))
            if bad:
                entry=tarfile.TarInfo(bad);entry.type=tarfile.SYMTYPE;entry.linkname='/etc/passwd';t.addfile(entry)
        line=hashlib.sha256(self.archive.read_bytes()).hexdigest()+'  '+self.archive.name+'\n';self.sums.write_text(line)
    def test_valid(self):
        self.write();b,_=g.verified_binary(self.archive,self.sums,self.tag,self.root);self.assertEqual(b.read_bytes(),b'ok')
    def test_bad_checksum(self):
        self.write();self.sums.write_text('0'*64+'  '+self.archive.name+'\n')
        with self.assertRaises(ValueError):g.verified_binary(self.archive,self.sums,self.tag,self.root)
        self.assertFalse((self.root/'engrt').exists())
    def test_duplicate_checksum(self):
        self.write();self.sums.write_text(self.sums.read_text()*2)
        with self.assertRaises(ValueError):g.verified_binary(self.archive,self.sums,self.tag,self.root)
    def test_link_refused(self):
        self.write('link')
        with self.assertRaises(ValueError):g.verified_binary(self.archive,self.sums,self.tag,self.root)
    def test_duplicate_executable(self):
        self.write(duplicate=True)
        with self.assertRaises(ValueError):g.verified_binary(self.archive,self.sums,self.tag,self.root)
    def test_prerelease_refused(self):
        with self.assertRaises(ValueError):g.generate(self.archive,self.sums,'v1.2.3-rc1')

class PublishTests(unittest.TestCase):
    def test_outdated_does_not_write(self):
        with tempfile.TemporaryDirectory() as d:
            path=Path(d)/'data.json';path.write_text(json.dumps({'provenance':{'runtime':{'ref':'v1.0.0'}}}))
            calls=[]
            def api(*args,**kwargs):
                calls.append(args);return {'tag_name':'v2.0.0','draft':False,'prerelease':False}
            original=p.api;p.api=api
            try:
                with self.assertRaises(ValueError):p.main(path)
            finally:p.api=original
            self.assertEqual(calls,[('releases/latest',)])

if __name__=='__main__':unittest.main()
