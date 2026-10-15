from pathlib import Path
import copy,hashlib,tempfile,unittest
from unittest.mock import patch
import execute

class ReviewBoundary(unittest.TestCase):
    def proof(self):
        return {'actual_cli_exit':0,'actual_hub_state':'ACCEPTED','actual_reviews':{execute.TASK:{'call':{'action':'review','arguments':{'task_id':execute.TASK,'verdict':'accept','error_count':0,'note':'stage-offload-inputs sha256 '+('a'*64)+' stage-offload-script sha256 '+('b'*64)}},'actual_response':{'id':execute.TASK,'state':'ACCEPTED','assignee':execute.AUTHOR,'reviewer':'different-provider-reviewer'}}}}
    def test_timeout_cannot_qualify_even_after_accepted_callback(self):
        proof=self.proof();proof['actual_cli_exit']='timeout'
        with self.assertRaises(AssertionError):execute.verify_review(proof,'a'*64,'b'*64)
    def test_wrong_packet_or_script_rejected(self):
        for a,b in [('c'*64,'b'*64),('a'*64,'c'*64)]:
            with self.assertRaises(AssertionError):execute.verify_review(self.proof(),a,b)
    def test_self_review_rejected(self):
        proof=self.proof();proof['actual_reviews'][execute.TASK]['actual_response']['reviewer']=execute.AUTHOR
        with self.assertRaises(AssertionError):execute.verify_review(proof,'a'*64,'b'*64)

class PhysicalCopies(unittest.TestCase):
    def setUp(self):
        tmp=tempfile.TemporaryDirectory();self.addCleanup(tmp.cleanup);self.root=Path(tmp.name).resolve();self.cold=self.root/'cold';self.cold.mkdir();self.old=self.root/'old.tar.gz';self.old.write_bytes(b'original-package')
        for name,value in [('COLD',self.cold),('OLD_COPY',self.old)]:
            ctx=patch.object(execute,name,value);ctx.start();self.addCleanup(ctx.stop)
        self.plan={'trees':[],'archives':[]};self.receipt={'actual_exit':0,'copies':[]}
        for i in range(9):
            name=f'failed-{i}';local=self.cold/(name+'.tar.gz');local.write_bytes(f'cold{i}'.encode());remote='/opt/quiz-master/stage-offload-20261015/'+local.name;sha=execute.digest(local)
            self.plan['trees'].append({'root':'/opt/quiz-master/releases/'+name,'entries':[{'kind':'dir'},{'kind':'file'}]});self.plan['archives'].append({'path':remote,'size':local.stat().st_size,'sha256':sha});self.receipt['copies'].append({'remote':remote,'local':str(local),'bytes':local.stat().st_size,'sha256':sha,'actual_exit':0,'members_verified':2,'permissions_and_ownership_verified':True,'full_gzip_crc_verified':True})
        oldremote='/opt/quiz-master/releases/original-failed.tar.gz';sha=execute.digest(self.old);self.plan['archives'].append({'path':oldremote,'size':self.old.stat().st_size,'sha256':sha});self.receipt['original_failed_package']={'remote':oldremote,'local':str(self.old),'bytes':self.old.stat().st_size,'sha256':sha}
    def test_rehash_detects_changed_cold_copy(self):
        execute.verify_copies(self.plan,self.receipt)
        Path(self.receipt['copies'][3]['local']).write_bytes(b'other')
        with self.assertRaises(AssertionError):execute.verify_copies(self.plan,self.receipt)
    def test_same_bytes_outside_private_root_rejected(self):
        c=self.receipt['copies'][0];escaped=self.root/Path(c['local']).name;escaped.write_bytes(Path(c['local']).read_bytes());c['local']=str(escaped)
        with self.assertRaises(AssertionError):execute.verify_copies(self.plan,self.receipt)

if __name__=='__main__':unittest.main()
