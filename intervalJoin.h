#ifndef __INTERVALJOIN_H__
#define __INTERVALJOIN_H__

#include <cstdlib>
#include <iostream>
#include <string>
#include <fstream>
using namespace std;

typedef struct{
  int count;
	int *category;
	int *length;
}SetA;

typedef struct{
  int count;
	int *category;
	int *length;	
}SetB;

SetA setA;
SetB setB;

int *start_index, *end_index;

int *inStartA, *inEndA;
int *inStartB, *inEndB;
char **inStringA;
char **inStringB;

int *outGPU_Begin, *outGPU_End;
int *outCPU_Begin, *outCPU_End;
int *outCPU_count;
int *outGPU_count;

//Read Metadata for csv files
void read_Meta(){
  FILE *mFile;
  int i;
  mFile = fopen ("data/metaA.csv","r");
  fscanf (mFile, "%d", &(setA.count));
  setA.category=new int [setA.count]();
  setA.length=new int [setA.count]();
  for(i=0;i<setA.count;i++)
  	fscanf(mFile,"%d,%d",&(setA.category[i]),&(setA.length[i]));
	fclose(mFile);
  mFile = fopen ("data/metaB.csv","r");
  fscanf (mFile, "%d", &(setB.count));
  setB.category=new int [setB.count]();
  setB.length=new int [setB.count]();
  for(i=0;i<setB.count;i++)
  	fscanf(mFile,"%d,%d",&(setB.category[i]),&(setB.length[i]));
	fclose(mFile);
}

//Read setA.csv or setB.csv
void init_from_csv(FILE *fpA, FILE *fpB, int id){
	int i,k;
  int temp;
  char string[]={'A','C','T','G'};
  
  
  inStartA=new int [setA.length[id]]();
	inEndA=new int [setA.length[id]]();
	inStringA=new char*[setA.length[id]]();
	for (unsigned int ith = 0; ith != setA.length[id]; ++ith)
		inStringA[ith] = new char[4];

	inStartB=new int [setB.length[id]]();
	inEndB=new int [setB.length[id]]();
	inStringB=new char*[setB.length[id]]();
  for (unsigned int ith = 0; ith != setB.length[id]; ++ith)
    inStringB[ith] = new char[4];
  int string_int;
  for(i=0;i<setA.length[id];i++){
	  fscanf(fpA,"%d,%d,%d,%d",&temp,&(inStartA[i]),&(inEndA[i]),&string_int);
	for(k=0;k<4;k++){
		int rem=string_int%10;
		string_int/=10;
		inStringA[i][3-k]=string[rem];
	}
  
  }
  for(i=0;i<setB.length[id];i++){
    fscanf(fpB,"%d,%d,%d,%d",&temp,&(inStartB[i]),&(inEndB[i]),&string_int);
    for(k=0;k<4;k++){
        int rem=string_int%10;
        string_int/=10;
        inStringB[i][3-k]=string[rem];
    }
  
  }
  outCPU_count=new int[setB.length[id]]();
  outGPU_count=new int[setB.length[id]]();
  
	outGPU_Begin=new int [setB.length[id]]();
	outGPU_End=new int [setB.length[id]]();
	outCPU_Begin=new int [setB.length[id]]();
	outCPU_End=new int [setB.length[id]]();
  for(i=0;i<setB.length[id];i++){
        outCPU_Begin[i]=INT_MAX;
        outCPU_End[i]=INT_MIN;
        outGPU_Begin[i]=INT_MAX;
        outGPU_End[i]=INT_MIN;
	      outCPU_count[i]=0;
	      outGPU_count[i]=0;
  }
}

void swap (int *a, int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}


void randomize ( int start[],int end[],char **string, int n, int m)
{
    srand ( time(NULL) );

    for (int i = n-1; i > 0; i--)
    {
        int j = rand() % (i+1);
        swap(&start[i], &start[j]);
        swap(&end[i], &end[j]);
        char temp;
        for(int k=0;k<m;k++){
            temp=string[i][k];
            string[i][k]=string[j][k];
            string[j][k]=temp;
        }
    }
}

void ending(int id)
{
	delete [] inStartA;
	delete [] inStartB;
	delete [] inEndA;
	delete [] inEndB;
	for(int i=0;i<setA.length[id];i++)
		delete [] inStringA[i];
	for(int i=0;i<setB.length[id];i++)
    delete [] inStringB[i];	
	delete [] outCPU_Begin;
	delete [] outGPU_Begin;
	delete [] outCPU_End;
	delete [] outGPU_End;
	delete [] outCPU_count;
	delete [] outGPU_count;
}

bool checker(int length){
	int i;
	for(i = 0; i < length; i++){ 
		if(outCPU_count[i] != outGPU_count[i]){
			cout << "The element: " << i << " is wrong!\n";
			cout << "outCPU_Count[" << i << "] = " << outCPU_count[i] << endl;
			cout << "outGPU_Count[" << i << "] = " << outGPU_count[i] << endl;
			return false;
		}
	}

	return true;
}

int timespec_diff_us(timespec& t1, timespec& t2)
{                                                                                
  return (t2.tv_sec - t1.tv_sec) * 1e6 + (t2.tv_nsec - t1.tv_nsec) / 1e3;        
} 

#endif
