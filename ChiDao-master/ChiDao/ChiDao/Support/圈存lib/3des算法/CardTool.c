
#include "CardTool.h"
#include "d3des.h"
//#include "freecard.h"

void DeliverKey(unsigned char* pRootKey, unsigned char* pDeliverFactor, unsigned char* pProcessKey)
{
	unsigned char buf1[8];long i;
	//����pDeliverFactor,�γɹ�����Կ����벿��
	des_en3(pRootKey,pDeliverFactor,8,pProcessKey);
	//��pDeliverFactorȡ��
	for(i=0;i<8;i++)
		buf1[i]=~pDeliverFactor[i];
	//����pDeliverFactor�ķ�,�γɹ�����Կ���Ұ벿��
	des_en3(pRootKey,buf1,8,pProcessKey+8);

}
 void f_getmac(unsigned char *chushi,unsigned char *key,unsigned char *buff,unsigned char *mac,int count)
 {    
	 int i,j;unsigned char zhong[16];

	 f_buff_xor(&buff[0],&chushi[0],8);
	 for( i=0;i<= 7;i++)
		 zhong[i]=buff[i];

	 for( i=0;i<= count-2;i++)
	 {
		 //		des_en1(UCHAR *key,UCHAR *mingwen,int m_len,UCHAR *miwen)
		 des_en1(&key[0],&zhong[0],8,&zhong[8]);
		 for( j=0;j<=7;j++)
			 zhong[j]=zhong[j+8];

		 f_buff_xor(&zhong[0],&buff[(i+1)*8],8);
	 }
	 des_en3(&key[0],&zhong[0],8,mac);

 }
 void f_getmac_single(unsigned char *chushi,unsigned char *key,unsigned char *buff,unsigned char *mac,int count)
 {    
	 int i,j;unsigned char zhong[16];
	 
	 f_buff_xor(buff,chushi,8);
	 for( i=0;i<= 7;i++)
		 zhong[i]=buff[i];

	 for( i=0;i<= count-2;i++)
	 {
		 //		des_en1(UCHAR *key,UCHAR *mingwen,int m_len,UCHAR *miwen)
		 des_en1(&key[0],&zhong[0],8,&buff[0]);
		 for( j=0;j<=7;j++)
			 zhong[j]=buff[j];
		 f_buff_xor(&zhong[0],&buff[(i+1)*8],8);
	 }
	 des_en1(&key[0],&zhong[0],8,&buff[0]);
	 for( j=0;j<4;j++)
		 mac[j]=buff[j];
 }
 void f_buff_xor(unsigned char *buf1,unsigned char *buf2,int i_len)
 {
	 int i;
	 for(i=0;i<i_len;i++)
	 {
		 *(buf1+i)=*(buf1+i) ^ *(buf2+i);
	 }
 }
 //��DES���� key:8�ֽ� m_len��8�ı���
  void des_en1(unsigned char *key,unsigned char *mingwen,int m_len,unsigned char *miwen)
 {
	 int i,iint_ks=0;
	 deskey(key,EN0);
	 iint_ks=m_len/8;
	 for(i=0;i<iint_ks;i++)
	 {
		 des(mingwen+i*8,miwen+i*8);
	 }
 }
 //��DES���� key:8�ֽ� m_len��8�ı���
 void des_de1(unsigned char *key,unsigned char *miwen,int m_len,unsigned char *mingwen)
 {
	 int i,iint_ks=0;
	 deskey(key,DE1);
	 iint_ks=m_len/8;
	 for(i=0;i<iint_ks;i++)
	 {
		 des(miwen+i*8,mingwen+i*8);
	 }
 }
 //3DES����  key:16�ֽ� m_len��8�ı���
 void des_en3(unsigned char *key,unsigned char *mingwen,int m_len,unsigned char *miwen)
 {
	 int i,iint_ks=0;unsigned char buf1[17],buf2[17];
	 des2key(key,EN0);
	 iint_ks=m_len/8;
	 for(i=0;i<iint_ks;i++)
	 {
		 memcpy(buf1,mingwen+i*8,8);
		 Ddes(buf1,buf2);
		 memcpy(miwen+i*8,buf2,8);
	 }
 }

 //3DES����  key:16�ֽ� m_len��8�ı���
 void des_de3(unsigned char *key,unsigned char *miwen,int m_len,unsigned char *mingwen)
 {
	 int i,iint_ks=0;unsigned char buf1[17],buf2[17];
	 des2key(key,DE1);
	 iint_ks=m_len/8;
	 for(i=0;i<iint_ks;i++)
	 {
		 memcpy(buf1,miwen+i*8,8);
		 Ddes(buf1,buf2);
		 memcpy(mingwen+i*8,buf2,8);
	 }
 }

void DataXOR( U08 *source, U08 *dest, U32 size, U08 *out )
{  
   int i;  
   for( i = 0; i < size; i++ )  
   { out[i] = dest[i] ^ source[i]; }  
} 

void PBOC_3DES_MAC( U08 *buf, U32 buf_size, U08 *key, U08 *mac_buf,U08 *iv)  
{  
    U08 val[8],xor[8];  
    U08 keyL[8],keyR[8];  
    U08 block[512];  
    U16 x,n;  
    U16 i;  
    memcpy(keyL,key,8);  
    memcpy(keyR,&key[8],8);  
    //׼������  
    memcpy( block, buf, buf_size ); //���������ݸ�ֵ����ʱ����block  
    x = buf_size / 8; //�����ж��ٸ������Ŀ�  
    n = buf_size % 8; //�������һ�����м����ֽ�  
    if( n != 0 )     //y��0,���������0x00...  
    {  
        memset( &block[x*8+n], 0x00, 8-n );  
        block[x*8+n]=0x80;    
    }  
    else  
    {  
        memset( &block[x*8], 0x00, 8 );//������һ�鳤����8���ֽڣ�������80 00����  
        block[x*8]=0x80;  
    }  
    //��ʼ����  
    memset( val, 0x00, 8 );//��ʼ����  
    memcpy( val, iv,8 );  
    DataXOR(val,&block[0], 8,xor);  
    for( i = 1; i < x+1; i++ )    //�ж��ٿ�ѭ�����ٴ�  
    {   
        des_en1(keyL,xor,8,val);//DES����  
        DataXOR(val,&block[i*8], 8,xor);  
        // j += 8;   //����ȡ��һ�������  
    }  
    des_en1(keyL,xor,8,val);  
    des_de1(keyR,val,8,xor);  
    des_en1(keyL,xor,8,val);  
    memcpy(mac_buf,val, 8 );  
}

#define CRC_A 1
#define CRC_B 2
