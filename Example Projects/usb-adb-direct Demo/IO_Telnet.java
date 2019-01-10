package re.anywhere.client;

import java.io.DataInputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.ServerSocket;
import java.net.Socket;

import android.os.SystemClock;

// uses Propeller style start/stop/rx/tx and should be compatible down to android 1.1
public class IO_Telnet {
	static public ServerSocket telnets=null;
	static public Socket io=null;
	static public OutputStreamWriter out=null;
	static public DataInputStream in=null;
	static public int port=65534;
	static public boolean running=false;
	static private boolean die=false;
	static public Thread telnetd=null;


	static public boolean start() 
	{
		return start(port);
	}
	static public boolean start(int prt)
	{
		if (telnetd != null)
			stop();
		port=prt;
		if (port<1024 || port>65535)
			return false;

		die=false;
		telnetd=new Thread(){
			public void run()
			{
				while (die==false)
				{
					try{
						telnets=new ServerSocket(port);
						telnets.setSoTimeout(3000);
						running=true;
						io=telnets.accept();
						// if we get past here, we have a connection!
						out=new OutputStreamWriter(io.getOutputStream());
						in=new DataInputStream(io.getInputStream());
						while(true)
						{
							SystemClock.sleep(500);
						}
					}
					catch(Exception e)
					{
						running=false;
						if (out != null)
							try {out.close();} catch (Exception e1) {e1.printStackTrace();}
							if (in != null)
								try {in.close();} catch (Exception e1) {e1.printStackTrace();}
								if (telnets != null)
									try {telnets.close();} catch (Exception e1) {e1.printStackTrace();}
									if (io != null)
										try {io.close();} catch (Exception e1) {e1.printStackTrace();}
										e.printStackTrace();
					}
				}

				running=false;
				if (out != null)
					try {out.close();} catch (Exception e1) {e1.printStackTrace();}
					if (in != null)
						try {in.close();} catch (Exception e1) {e1.printStackTrace();}
						if (telnets != null)
							try {telnets.close();} catch (Exception e1) {e1.printStackTrace();}
							if (io != null)
								try {io.close();} catch (Exception e1) {e1.printStackTrace();}

			}
		};
		telnetd.start();
		SystemClock.sleep(50);
		return running;
	}

	static public void stop(){
		try{telnetd.interrupt();}catch(Exception e){e.printStackTrace();};
		die=true;
		SystemClock.sleep(20);
		telnetd=null;
	}

	static public int rxcheck()
	{
		try {
			if (in.available()>0)
			{
				return in.readByte();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}	
		return -1;
	}
	
	static public boolean tx(byte txme){
		if (running)
		{
			try {
				out.write(txme);
				out.flush();
				return true;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
		return false;
	}
	static public boolean str(String str){
		if (running)
		{
			try {
				out.write(str);
				out.flush();
				return true;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
		return false;
	}
}
